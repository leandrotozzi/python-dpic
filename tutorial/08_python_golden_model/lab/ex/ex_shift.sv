`timescale 1ns/1ps
// Ex. 12.1 with a Python golden model: shift(i, n) through the generic bridge, checked against SV.
module top;
  import py_extra_pkg::*;                                         // py_call_i64
  longint a[2];
  int unsigned i, exp_v, got;
  int n, n_err;
  initial begin
    for (int k = 0; k < 200; k++) begin
      i = $urandom; n = $urandom_range(0, 70) - 35;                 // includes |n| >= 32
      if (k == 0) n = 0;
      a = '{longint'(i), longint'(n)};
      got = 32'(py_call_i64("ex_models", "shift", a));
      exp_v = (n >= 0) ? i << n : i >> -n;                          // SV: shift >= width gives 0
      if (got !== exp_v) begin n_err++; $display("MISMATCH i=%h n=%0d py=%h sv=%h", i, n, got, exp_v); end
    end
    $display("LOG ex_shift n=200 errors=%0d", n_err);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
