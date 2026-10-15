// The recommended home for imports: a package (Spear §12.1.2). Two modules share one declaration.
package dpi_pkg;
  import "DPI-C" pure function int factorial(input int i);
endpackage
module child;
  import dpi_pkg::*;
  initial $display("LOG pkg who=%m f6=%0d", factorial(6));
endmodule
module top;
  import dpi_pkg::*;
  child c1();
  child c2();
  initial begin #1 $display("LOG pkg who=%m f7=%0d", factorial(7)); $finish; end
endmodule
