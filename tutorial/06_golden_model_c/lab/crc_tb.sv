// Layered self-checking TB for common/rtl/crc32_stream.sv with the C golden model (golden_pkg).
// Plusargs: +SEED=<n>  +MSGS=<messages>  +MODE=stream|batch  +FLIP=<k> (corrupt crc on checked cycle #k)
`timescale 1ns/1ps
interface crc_if (input logic clk);
  logic rst_n, clear, in_valid;
  logic [7:0]  in_data;
  logic [31:0] crc;
  clocking cb @(posedge clk);
    output clear, in_valid, in_data;
    input  clear_s = clear, in_valid_s = in_valid, in_data_s = in_data, crc;
  endclocking
endinterface

package crc_tb_pkg;
  import golden_pkg::*;
  localparam int MAXLEN = 256;

  class crc_msg;                                       // one message = a CRC'd frame
    rand byte unsigned data[];
    rand int unsigned  gap[];                          // idle cycles before each byte
    rand bit           clear_with_valid;               // last cycle: clear AND a byte (clear wins)
    constraint c_len  { data.size() dist {0 := 2, [1:8] :/ 30, [9:64] :/ 50, [65:MAXLEN] :/ 18};
                        gap.size() == data.size(); }
    constraint c_data { foreach (data[i]) data[i] dist {8'h00 := 1, 8'hFF := 1, [1:254] :/ 8}; }
    constraint c_gap  { foreach (gap[i]) gap[i] dist {0 := 8, [1:3] :/ 2}; }
  endclass

  class crc_driver;
    virtual crc_if vif;
    function new(virtual crc_if vif); this.vif = vif; endfunction
    task send(crc_msg m);
      foreach (m.data[i]) begin
        repeat (m.gap[i]) @(vif.cb) begin vif.cb.in_valid <= 0; vif.cb.clear <= 0; end
        @(vif.cb) begin vif.cb.in_valid <= 1; vif.cb.in_data <= m.data[i]; vif.cb.clear <= 0; end
      end
      @(vif.cb) begin                                  // end of frame: clear (maybe with a stray byte)
        vif.cb.clear <= 1; vif.cb.in_valid <= m.clear_with_valid; vif.cb.in_data <= 8'hA5;
      end
    endtask
  endclass

  // stream: the model tracks the DUT every cycle (crc32_update), checking the crc output on every
  // edge. batch: only the final CRC of each frame is checked, with one crc32_msg call per frame.
  class crc_scoreboard;
    chandle h;
    bit batch;
    int unsigned cur;                                  // model's view of the DUT crc output
    byte unsigned frame[$];
    int n_cmp, n_err, first_err = -1, n_frames;
    function new(bit batch); h = crc32_new(); this.batch = batch; cur = 0; endfunction

    // called once per clock edge with the values sampled just before the edge
    function void edge_seen(int cyc, bit clear, bit valid, byte unsigned b, int unsigned dut_crc);
      if (!batch) compare(cyc, cur, dut_crc, "cycle");
      if (clear) begin
        if (batch) begin
          byte unsigned buffer[MAXLEN];                // fixed-size actual for the open array
          foreach (frame[i]) buffer[i] = frame[i];
          compare(cyc, crc32_msg(buffer, frame.size()), dut_crc, "frame");
        end
        n_frames++;
        frame.delete();
        crc32_clear(h); cur = 0;                       // ~0xFFFFFFFF: CRC of the empty message
      end else if (valid) begin
        frame.push_back(b);
        if (!batch) cur = crc32_update(h, b);
      end
    endfunction

    function void compare(int cyc, int unsigned exp, int unsigned got, string what);
      n_cmp++;
      if (exp === got) return;
      n_err++;
      if (first_err < 0) first_err = cyc;
      if (n_err <= 5)
        $display("LOG mismatch model=crc32 kind=%s cycle=%0d frame=%0d byte=%0d exp=%h got=%h",
                 what, cyc, n_frames, frame.size(), exp, got);
    endfunction

    function bit report();
      $display("LOG crc_sb mode=%0s frames=%0d compared=%0d errors=%0d first=%0d",
               batch ? "batch" : "stream", n_frames, n_cmp, n_err, first_err);
      crc32_free(h);
      return n_err == 0;
    endfunction
  endclass

  class crc_monitor;
    virtual crc_if vif;
    crc_scoreboard sb;
    int flip = -1, cyc;
    function new(virtual crc_if vif, crc_scoreboard sb); this.vif = vif; this.sb = sb; endfunction
    task run();
      forever begin
        @(vif.cb);
        if (vif.rst_n !== 1'b1) continue;
        sb.edge_seen(cyc, vif.cb.clear_s, vif.cb.in_valid_s, vif.cb.in_data_s,
                     vif.cb.crc ^ (cyc == flip ? 32'h8000_0000 : 0));   // fake DUT bug on cycle #flip
        cyc++;
      end
    endtask
  endclass
endpackage

module top;
  import golden_pkg::*;
  import crc_tb_pkg::*;

  logic clk = 0;
  always #5 clk = ~clk;
  crc_if vif (clk);
  crc32_stream dut (.clk, .rst_n(vif.rst_n), .clear(vif.clear), .in_valid(vif.in_valid),
                    .in_data(vif.in_data), .crc(vif.crc));

  initial begin
    int unsigned seed = 1, msgs = 40, bytes = 0;
    int flip = -1;
    string mode = "stream";
    crc_msg m; crc_driver d; crc_monitor mon; crc_scoreboard sb;
    byte unsigned check[9] = '{"1", "2", "3", "4", "5", "6", "7", "8", "9"};
    void'($value$plusargs("SEED=%d", seed));
    void'($value$plusargs("MSGS=%d", msgs));
    void'($value$plusargs("MODE=%s", mode));
    void'($value$plusargs("FLIP=%d", flip));
    process::self().srandom(seed);
    $display("LOG crc_check model=%h", crc32_msg(check, 9));    // catalogue check value CBF43926
    vif.rst_n = 0; vif.clear = 0; vif.in_valid = 0; vif.in_data = 0;
    m = new(); d = new(vif); sb = new(mode == "batch"); mon = new(vif, sb); mon.flip = flip;
    repeat (2) @(posedge clk);
    vif.rst_n = 1;
    fork mon.run(); join_none
    repeat (msgs) begin
      if (!m.randomize()) $fatal(1, "randomize failed");
      bytes += m.data.size();
      d.send(m);
    end
    @(vif.cb) begin vif.cb.clear <= 0; vif.cb.in_valid <= 0; end
    repeat (2) @(vif.cb);
    $display("LOG crc_run seed=%0d msgs=%0d bytes=%0d", seed, msgs, bytes);
    if (sb.report()) $display("PASS crc32"); else $display("FAIL crc32");
    $finish;
  end
endmodule
