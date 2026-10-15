`timescale 1ns/1ps
// Ex. 10: signed 100-bit values across the bridge, checked against SV's own negation (which wraps).
module top;
  import py_extra_pkg::*;
  import "DPI-C" function void py_neg100(input bit signed [99:0] a, output bit signed [99:0] y);
  bit signed [99:0] a, y;
  int n_err;
  string e;
  initial begin
    for (int k = 0; k < 500; k++) begin
      case (k)
        0: a = -100'sd1;
        1: a = 100'sd1 <<< 99;                                       // -2**99: negation wraps to itself
        2: a = (100'sd1 <<< 99) - 1;                                 // +2**99 - 1
        3: a = 0;
        default: a = {$urandom, $urandom, $urandom, 4'($urandom)};
      endcase
      py_neg100(a, y);
      e = py_last_error();
      if (e != "" || y !== -a) begin n_err++; $display("MISMATCH a=%h y=%h sv=%h err='%s'", a, y, -a, e); end
      if (k == 1) $display("LOG signed min_neg=%h", y);
    end
    $display("LOG ex_signed n=500 errors=%0d", n_err);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
