// 35.4: two exports may share one C name (here "hello") in different scopes if their signatures
// are equivalent. C picks the instance with svSetScope before each call.
module top;
  ma u1();
  mb u2();
  import "DPI-C" context function void call_both();
  initial begin call_both(); $finish; end
endmodule
module ma; export "DPI-C" function hello; function void hello(); $display("LOG xshared who=%m kind=a"); endfunction endmodule
module mb; export "DPI-C" function hello; function void hello(); $display("LOG xshared who=%m kind=b"); endfunction endmodule
