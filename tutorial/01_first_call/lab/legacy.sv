// "DPI" (without -C) is the IEEE 1800-2005 spelling, deprecated since 1800-2009.
module top;
  import "DPI" function int factorial(input int i);
  initial begin $display("LOG legacy f5=%0d", factorial(5)); $finish; end
endmodule
