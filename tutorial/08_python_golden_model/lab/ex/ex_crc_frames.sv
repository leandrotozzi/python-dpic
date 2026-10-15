`timescale 1ns/1ps
// Ex. 7: Ethernet-style frames. The FCS (the CRC of the payload) is appended least-significant byte
// first; the CRC of payload+FCS is then the constant residue 0x2144DF1C, in the DUT and in the model.
module top;
  import golden_pkg::*;
  logic clk = 0, rst_n = 0, clear = 0, in_valid = 0;
  logic [7:0] in_data;
  logic [31:0] crc;
  crc32_stream dut (.*);
  always #5 clk = ~clk;
  byte unsigned frame[1504];
  int unsigned fcs, model;
  int n_err;
  initial begin
    repeat (2) @(negedge clk);
    rst_n = 1;
    for (int f = 0; f < 20; f++) begin
      automatic int len = $urandom_range(46, 1500);
      foreach (frame[i]) frame[i] = 8'($urandom);
      fcs = crc32_msg(frame, len);
      for (int k = 0; k < 4; k++) frame[len + k] = fcs[8*k +: 8];
      clear = 1; @(negedge clk); clear = 0;
      for (int i = 0; i < len + 4; i++) begin in_valid = 1; in_data = frame[i]; @(negedge clk); end
      in_valid = 0;
      model = crc32_msg(frame, len + 4);
      if (crc !== 32'h2144DF1C || model !== 32'h2144DF1C) begin
        n_err++; $display("MISMATCH frame %0d dut=%h model=%h", f, crc, model);
      end
    end
    $display("LOG ex_crc_frames frames=20 residue=%h errors=%0d", crc, n_err);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
