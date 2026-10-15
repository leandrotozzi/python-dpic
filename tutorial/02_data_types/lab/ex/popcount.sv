// Exercise 5: popcount of a 200-bit vector in C.
import "DPI-C" function int c_popcount200(input bit [199:0] v);
module top;
  bit [199:0] v;
  int errs = 0;
  initial begin
    for (int t = 0; t < 1000; t++) begin
      v = {$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom};
      if (t == 0) v = '1;
      if (t == 1) v = '0;
      if (c_popcount200(v) != $countones(v)) errs++;
    end
    $display("LOG ex_popcount all_ones=%0d errs=%0d", c_popcount200('1), errs);
    if (errs == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
