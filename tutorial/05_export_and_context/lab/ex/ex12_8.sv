`timescale 1ns/1ns
// Ex. 12.8: shift_c (C) delegates the shift to an exported SV function shift_sv.
// Bonus: SV defines shifts >= 32 (result 0); in C `x << 40` on a 32-bit int is undefined behavior.
module top;
  import "DPI-C" context function int unsigned shift_c(int unsigned i, int n);
  export "DPI-C" function shift_sv;
  function void shift_sv(input int unsigned i, input int n, output int unsigned o);
    o = (n > 0) ? i << n : (n < 0) ? i >> -n : i;
  endfunction
  int ns[5] = '{4, -4, 0, 40, -31};
  initial begin
    foreach (ns[k]) $display("LOG ex8 n=%0d o=%h", ns[k], shift_c(32'h8000_00F0, ns[k]));
    $finish;
  end
endmodule
