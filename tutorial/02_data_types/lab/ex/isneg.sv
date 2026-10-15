// Exercise 9: is a byte negative? Built twice: default (x86: char signed) and -funsigned-char (like ARM Linux).
import "DPI-C" function int c_isneg_bad(input byte b);
import "DPI-C" function int c_isneg    (input byte b);
module top;
  int errs = 0;
  initial begin
    for (int b = -128; b < 128; b++) if (c_isneg(byte'(b)) != (b < 0)) errs++;
    $display("LOG ex_isneg bad_m5=%0d good_m5=%0d errs=%0d", c_isneg_bad(-5), c_isneg(-5), errs);
    if (errs == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
