// Two scopes import the same C symbol with different SV signatures: illegal (IEEE 1800-2023 35.5.4).
package pa; import "DPI-C" function int twice(input int x); endpackage
package pb; import "DPI-C" function real twice(input real x); endpackage
module top;
  initial begin $display("%0d %f", pa::twice(1), pb::twice(1.0)); $finish; end
endmodule
