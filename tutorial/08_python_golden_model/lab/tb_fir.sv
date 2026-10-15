`timescale 1ns/1ps
// Two fir8 instances, two model instances (two chandles), compared per sample or per block.
// Only step 06's contract (golden_pkg): links against golden.c (C) or golden_py.c (Python).
// +block : collect BLK accepted samples per instance, one fir8_block call per block
// Bug injection is the backend's business: -DMUTANT=1 for golden.c, GOLDEN_BUG=fir_trunc for Python.
module top;
  import golden_pkg::*;
  localparam int N = 2048, BLK = 256;          // N multiple of BLK: no partial block
  logic clk = 0, rst_n = 0, in_valid = 0;
  shortint coef [2][8];                                 // shortint, not logic [15:0]: see the guide
  logic signed [15:0] in_x, out_y [2];
  logic out_valid [2];
  always #5 clk = ~clk;
  for (genvar u = 0; u < 2; u++) begin : g
    fir8 dut (.clk, .rst_n, .coef(coef[u]), .in_valid, .in_x, .out_valid(out_valid[u]), .out_y(out_y[u]));
  end

  chandle h [2];
  shortint xs [BLK], ys [2][BLK], ym [BLK];
  int nb, n_calls, n_err, first_bad = -1, n_sat;

  function automatic void cmp(int u, int idx, shortint dut_y, shortint model_y);
    if (dut_y !== model_y) begin
      n_err++;
      if (first_bad < 0) begin
        first_bad = idx;
        $display("LOG first_mismatch unit=%0d sample=%0d dut=%0d model=%0d", u, idx, dut_y, model_y);
      end
    end
  endfunction

  initial begin
    coef[0] = '{16'sh4000, -16'sh2000, 16'sh1000, 16'sh7fff, -16'sh8000, 16'sh0800, 16'sh0001, -16'sh0001};
    coef[1] = '{16'sh0400, 16'sh0c00, 16'sh1800, 16'sh2400, 16'sh2400, 16'sh1800, 16'sh0c00, 16'sh0400};  // low-pass
    for (int u = 0; u < 2; u++) h[u] = fir8_new(coef[u]);
    repeat (2) @(negedge clk);
    rst_n = 1;
    for (int n = 0; n < N; n++) begin
      while ($urandom_range(0, 4) == 0) @(negedge clk);           // idle cycles: delay line must hold
      in_valid = 1;
      in_x = (n % 50 == 7) ? 16'sh7fff : (n % 50 == 8) ? -16'sh8000 : 16'($urandom);
      @(negedge clk);                                              // out_y now holds y for in_x
      in_valid = 0;
      for (int u = 0; u < 2; u++) n_sat += (out_y[u] == 32767 || out_y[u] == -32768);
      if (!$test$plusargs("block")) begin
        for (int u = 0; u < 2; u++) begin
          automatic shortint y = fir8_step(h[u], in_x); n_calls++;
          cmp(u, n, out_y[u], y);
        end
      end else begin
        xs[nb] = in_x; ys[0][nb] = out_y[0]; ys[1][nb] = out_y[1];
        if (++nb == BLK) begin
          for (int u = 0; u < 2; u++) begin
            fir8_block(h[u], xs, ym, nb); n_calls++;
            for (int i = 0; i < nb; i++) cmp(u, n - nb + 1 + i, ys[u][i], ym[i]);
          end
          nb = 0;
        end
      end
    end
    for (int u = 0; u < 2; u++) fir8_free(h[u]);
    $display("LOG fir samples=%0d calls=%0d errors=%0d saturated=%0d", N, n_calls, n_err, n_sat);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
