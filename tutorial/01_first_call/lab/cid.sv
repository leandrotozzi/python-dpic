// IEEE 1800-2023 35.4 / 35.5.4: one C name (c_identifier) may be imported in several scopes under
// different SV names and argument names, but every declaration must have the same signature,
// including the pure/context qualifiers. -DBAD makes the second declaration context.
module top;
  import "DPI-C" function int twice(input int x);
  m u();
  initial begin $display("LOG cid top=%0d u=%0d", twice(2), u.dbl(3)); $finish; end
endmodule
module m;
`ifdef BAD
  import "DPI-C" context twice = function int dbl(input int y);   // qualifier differs: illegal
`else
  import "DPI-C" twice = function int dbl(input int y);           // same signature: legal
`endif
endmodule
