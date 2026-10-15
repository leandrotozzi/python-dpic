// `ref` is not a legal direction for an import argument (IEEE 1800-2023 35.5.6; Spear 12.1.3).
module top;
  import "DPI-C" function void bump(ref int x);
  int v; initial begin bump(v); $finish; end
endmodule
