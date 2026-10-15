// Layered self-checking TB for common/rtl/fir8.sv with the C golden model (golden_pkg).
// Plusargs: +SEED=<n>  +N=<samples>  +MODE=stream|batch  +FLIP=<k> (corrupt output #k: a fake DUT bug)
//           +FAST (stimulus from $urandom instead of randomize(): same distribution, no solver)
`timescale 1ns/1ps
interface fir_if (input logic clk);
  logic rst_n, in_valid, out_valid;
  logic signed [15:0] coef [8];
  logic signed [15:0] in_x, out_y;
  clocking cb @(posedge clk);                  // sample just before the edge, drive just after it
    output in_valid, in_x;
    input  in_valid_s = in_valid, in_x_s = in_x, out_valid, out_y;
  endclocking
endinterface

package fir_tb_pkg;
  import golden_pkg::*;

  class fir_txn;
    rand bit      valid;
    rand shortint x;
    constraint c_valid { valid dist {1 := 8, 0 := 2}; }            // random bubbles
    // saturation corners get explicit weight. Plain decimal literals: in Verilator 5.052 a
    // sized `-16'sh8000` inside dist is unsatisfiable (see NOTES.md).
    constraint c_x { x dist {32767 := 5, -32768 := 5, 0 := 5, [-100:100] :/ 15, [-32767:32766] :/ 70}; }
    // Same distribution with $urandom: Verilator's randomize() calls an external SMT solver (z3),
    // ~5 ms per call, which buries everything else when you want to measure the DPI cost.
    function void fast_randomize();
      int unsigned b = $urandom_range(99);
      valid = $urandom_range(9) < 8;
      x = b < 5 ? 32767 : b < 10 ? -32768 : b < 15 ? 0 : b < 30 ? shortint'($urandom_range(200)) - 100
                                                                 : shortint'($urandom_range(65533)) - 32767;
    endfunction
  endclass

  class fir_driver;
    virtual fir_if vif;
    bit fast;                                                       // +FAST: $urandom stimulus
    function new(virtual fir_if vif); this.vif = vif; endfunction
    task run(int n);                                                // n accepted samples
      fir_txn t = new();
      for (int sent = 0; sent < n; ) begin
        if (fast) t.fast_randomize();
        else if (!t.randomize()) $fatal(1, "randomize failed");
        @(vif.cb);
        vif.cb.in_valid <= t.valid;
        vif.cb.in_x     <= t.x;
        sent += t.valid;
      end
      @(vif.cb) vif.cb.in_valid <= 1'b0;
      repeat (2) @(vif.cb);                                         // drain the 1-cycle latency
    endtask
  endclass

  // The scoreboard owns the golden model. stream: one DPI call per input, compare each output
  // as it appears. batch: record both streams, one DPI call per block of BLK at end of test.
  class fir_scoreboard;
    localparam int BLK = 256;
    chandle  h;
    bit      batch;
    shortint xs[$], ys[$], exp_q[$];
    int      n_cmp, n_err, first_err = -1;

    function new(shortint coef[8], bit batch);
      h = fir8_new(coef);
      this.batch = batch;
    endfunction

    function void write_in(shortint x);
      xs.push_back(x);
      if (!batch) exp_q.push_back(fir8_step(h, x));   // compare happens when y shows up
    endfunction

    function void write_out(shortint y);
      ys.push_back(y);
      if (!batch) begin
        if (exp_q.size() == 0) begin error(ys.size() - 1, 0, y, "output with no input"); return; end
        compare(ys.size() - 1, exp_q.pop_front(), y);
      end
    endfunction

    function void compare(int i, shortint exp, shortint got);
      n_cmp++;
      if (exp !== got) error(i, exp, got, "value");
    endfunction

    function void error(int i, shortint exp, shortint got, string what);
      n_err++;
      if (first_err < 0) first_err = i;
      if (n_err <= 5)                                  // first few in full, then just count
        $display("LOG mismatch model=fir8 kind=%s idx=%0d x=%0d exp=%0d got=%0d", what, i,
                 i < xs.size() ? xs[i] : 0, exp, got);
    endfunction

    function void check_batch();
      shortint xb[BLK], yb[BLK];                       // fixed-size: what DPI open arrays accept here
      for (int base = 0; base < xs.size(); base += BLK) begin
        int n = (xs.size() - base < BLK) ? xs.size() - base : BLK;
        for (int i = 0; i < n; i++) xb[i] = xs[base + i];
        fir8_block(h, xb, yb, n);
        for (int i = 0; i < n && base + i < ys.size(); i++) compare(base + i, yb[i], ys[base + i]);
      end
    endfunction

    function bit report();
      if (batch) check_batch();
      if (ys.size() != xs.size()) error(ys.size(), 0, 0, "count");
      $display("LOG fir_sb mode=%0s in=%0d out=%0d compared=%0d errors=%0d first=%0d",
               batch ? "batch" : "stream", xs.size(), ys.size(), n_cmp, n_err, first_err);
      fir8_free(h);
      return n_err == 0;
    endfunction
  endclass

  class fir_monitor;
    virtual fir_if vif;
    fir_scoreboard sb;
    int flip = -1, n_out;
    function new(virtual fir_if vif, fir_scoreboard sb); this.vif = vif; this.sb = sb; endfunction
    task run();
      forever begin
        @(vif.cb);
        if (vif.rst_n !== 1'b1) continue;
        if (vif.cb.out_valid) begin                    // output of the input accepted one edge ago
          shortint y = vif.cb.out_y;
          if (n_out == flip) y ^= 16'h0001;            // fake DUT bug: LSB flipped on output #flip
          sb.write_out(y);
          n_out++;
        end
        if (vif.cb.in_valid_s) sb.write_in(vif.cb.in_x_s);
      end
    endtask
  endclass
endpackage

module top;
  import golden_pkg::*;
  import fir_tb_pkg::*;
  import "DPI-C" function real wall_s();

  logic clk = 0;
  always #5 clk = ~clk;
  fir_if vif (clk);
  fir8 dut (.clk, .rst_n(vif.rst_n), .coef(vif.coef), .in_valid(vif.in_valid), .in_x(vif.in_x),
            .out_valid(vif.out_valid), .out_y(vif.out_y));

  initial begin
    int unsigned seed = 1, n = 2000, digest = 0;
    int flip = -1;
    string mode = "stream";
    shortint coef [8];
    fir_driver d; fir_monitor m; fir_scoreboard sb;
    real t0;
    void'($value$plusargs("SEED=%d", seed));
    void'($value$plusargs("N=%d", n));
    void'($value$plusargs("MODE=%s", mode));
    void'($value$plusargs("FLIP=%d", flip));
    process::self().srandom(seed);                     // everything below derives from SEED
    foreach (coef[k])                                  // random taps, with the extreme codes likely
      coef[k] = ($urandom_range(3) == 0) ? (($urandom_range(1)) ? 16'sd32767 : -16'sd32768) : 16'($urandom);
    foreach (coef[k]) digest = digest * 31 + 32'(coef[k]);
    foreach (coef[k]) vif.coef[k] = coef[k];          // shortint[8] -> logic[15:0][8]: element-wise
    vif.rst_n = 0; vif.in_valid = 0; vif.in_x = 0;
    sb = new(coef, mode == "batch");
    d = new(vif); m = new(vif, sb); m.flip = flip; d.fast = $test$plusargs("FAST");
    repeat (2) @(posedge clk);
    vif.rst_n = 1;
    t0 = wall_s();
    fork m.run(); join_none
    d.run(n);
    foreach (sb.xs[i]) digest = digest * 31 + 32'(sb.xs[i]);
    $display("LOG fir_run seed=%0d n=%0d fast=%0d digest=%h sat=%0d wall_ms=%0d", seed, n, d.fast, digest,
             count_sat(sb.ys), int'((wall_s() - t0) * 1000));
    if (sb.report()) $display("PASS fir8"); else $display("FAIL fir8");
    $finish;
  end

  function automatic int count_sat(shortint ys[$]);
    foreach (ys[i]) if (ys[i] == 16'sh7fff || ys[i] == -16'sh8000) count_sat++;
  endfunction
endmodule
