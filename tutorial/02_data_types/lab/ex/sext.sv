// Exercise 6: a signed 40-bit value into a C long long. c_s40_bad is the buggy version, c_s40 the fix.
import "DPI-C" function longint c_s40_bad(input bit signed [39:0] v);
import "DPI-C" function longint c_s40    (input bit signed [39:0] v);
module top;
  bit signed [39:0] vals[] = '{40'sd0, 40'sd1, -40'sd1, -40'sd2, 40'sh7F_FFFF_FFFF, -40'sh80_0000_0000};
  int errs = 0;
  initial begin
    foreach (vals[k]) if (c_s40(vals[k]) != longint'(vals[k])) errs++;
    $display("LOG ex_sext bad_m2=%0d good_m2=%0d errs=%0d", c_s40_bad(-40'sd2), c_s40(-40'sd2), errs);
    if (errs == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
