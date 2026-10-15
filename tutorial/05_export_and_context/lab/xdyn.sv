// 35.5.6: a dynamic-array formal on an exported function is erroneous (and open arrays exist
// only in import declarations, 35.5.6.1). A native `int a[]` formal is a dynamic array.
module top;
  export "DPI-C" function sum_dyn;
  function int sum_dyn(input int a[]); return a.sum(); endfunction
  initial $finish;
endmodule
