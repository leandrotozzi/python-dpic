`timescale 1ns/1ns
// Ex. 12.9 + 12.10: many Shift objects, C addresses them by queue index (handles can't cross DPI).
module top;
  import "DPI-C" context function void c_run();
  export "DPI-C" function shift_build;
  export "DPI-C" function shift_sv;
  export "DPI-C" function shift_print;

  class Shift;
    int unsigned result;
    function void shift_sv(int unsigned i, int n);
      result = (n > 0) ? i << n : (n < 0) ? i >> -n : i;
    endfunction
    function void shift_print(int idx);
      $display("LOG ex10 idx=%0d result=%h", idx, result);
    endfunction
  endclass

  Shift q[$];
  function automatic int shift_build();
    Shift s = new();                   // automatic: a fresh object per call
    q.push_back(s);
    return q.size() - 1;
  endfunction
  function void shift_sv(int idx, int unsigned i, int n); q[idx].shift_sv(i, n); endfunction
  function void shift_print(int idx);                     q[idx].shift_print(idx); endfunction

  initial begin
    c_run();
    $display("LOG ex10 n=%0d", q.size());
    $finish;
  end
endmodule
