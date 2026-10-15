// Exercise 10: 64x64 -> 128-bit unsigned product in C, checked against SV.
import "DPI-C" function void c_mul128(input longint unsigned a, b, output bit [127:0] p);
module top;
  longint unsigned a, b;
  bit [127:0] p;
  int errs = 0;
  initial begin
    for (int t = 0; t < 2000; t++) begin
      a = {$urandom, $urandom}; b = {$urandom, $urandom};
      if (t == 0) begin a = '1; b = '1; end
      c_mul128(a, b, p);
      if (p != 128'(a) * 128'(b)) errs++;
    end
    c_mul128(64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF, p);
    $display("LOG ex_mul128 max=%h errs=%0d", p, errs);
    if (errs == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
