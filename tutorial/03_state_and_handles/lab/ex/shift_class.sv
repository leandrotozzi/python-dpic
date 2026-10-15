// Ex. 12.6: the shifter of Ex. 12.5 encapsulated in a class; the chandle never leaves it.
import "DPI-C" function chandle shift_new(input int unsigned init);
import "DPI-C" function void shift_free(input chandle h);
import "DPI-C" function int  shift_total();
import "DPI-C" function int unsigned shift_c(input chandle h, input int unsigned i, input int n, input bit ld);

class Shift;
  local chandle h;
  function new(int unsigned init = 0); h = shift_new(init); endfunction
  function void free(); if (h != null) shift_free(h); h = null; endfunction
  function int unsigned load(int unsigned i, int n = 0); return shift_c(h, i, n, 1); endfunction
  function int unsigned shift(int n);                   return shift_c(h, 0, n, 0); endfunction
endclass

module top;
  Shift s1, s2;
  initial begin
    s1 = new(32'hF);  s2 = new;
    void'(s2.load(32'hAB, 8));                       // AB00
    $display("LOG ex6 s1=%h s2=%h total=%0d", s1.shift(4), s2.shift(-4), shift_total());   // F0, 0AB0
    s1.free(); s2.free();
    $finish;
  end
endmodule
