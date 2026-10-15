`timescale 1ns/1ps
// Scoreboard for crc32_stream against step 06's contract (golden_pkg). The same source links
// against 06's golden.c (C) or this step's golden_py.c (Python).
// +per_byte : crc32_update once per accepted byte, DUT checked every byte
// default   : crc32_msg once per message, DUT checked at the end of the message
module top;
  import golden_pkg::*;
  import "DPI-C" function real wall_s();                         // 06's wall.c
  logic clk = 0, rst_n = 0, clear = 0, in_valid = 0;
  logic [7:0] in_data;
  logic [31:0] crc;
  crc32_stream dut (.*);
  always #5 clk = ~clk;

  byte unsigned msg[256];
  int unsigned exp_crc;
  int n_msgs, n_bytes, n_calls, n_chk, n_err;
  bit per_byte;
  chandle h;
  real t0;

  function automatic void check(string what);
    n_chk++;
    if (crc !== exp_crc) begin
      n_err++;
      if (n_err <= 3) $display("MISMATCH %s dut=%h model=%h", what, crc, exp_crc);
    end
  endfunction

  initial begin
    per_byte = $test$plusargs("per_byte");
    h = crc32_new();
    repeat (2) @(negedge clk);
    rst_n = 1;
    t0 = wall_s();
    for (int m = 0; m < 300; m++) begin
`ifdef STATIC_BUG
      int len = (m == 0) ? 0 : (m == 1) ? 9 : $urandom_range(1, 256);            // exercise 5: see the guide
`else
      automatic int len = (m == 0) ? 0 : (m == 1) ? 9 : $urandom_range(1, 256);  // empty, "123456789", random
`endif
      clear = 1; @(negedge clk); clear = 0;
      crc32_clear(h);
      exp_crc = 0;                                                 // CRC of the empty message
      for (int i = 0; i < len; i++) begin
        msg[i] = (m == 1) ? 8'(49 + i) : 8'($urandom);
        while ($urandom_range(0, 3) == 0) @(negedge clk);         // random idle cycles
        in_valid = 1; in_data = msg[i];
        @(negedge clk);                                            // DUT took the byte at the posedge
        in_valid = 0;
        n_bytes++;
        if (per_byte) begin
          exp_crc = crc32_update(h, msg[i]); n_calls++;
          check($sformatf("msg %0d byte %0d", m, i));
        end
      end
      if (!per_byte) begin
        exp_crc = crc32_msg(msg, len); n_calls++;
        check($sformatf("msg %0d", m));
      end
      if (m == 1) $display("LOG crc check_value=%h", crc);
      n_msgs++;
    end
    crc32_free(h);
    $display("LOG crc msgs=%0d bytes=%0d calls=%0d checks=%0d errors=%0d wall_ms=%0d",
             n_msgs, n_bytes, n_calls, n_chk, n_err, int'((wall_s() - t0) * 1e3));
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
