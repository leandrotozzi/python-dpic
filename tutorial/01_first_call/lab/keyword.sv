// BUG: "expect" is an SV keyword, so it cannot be the SV name of an import (Sample 12.3).
module top;
  import "DPI-C" function int expect();
  initial $display("%0d", expect());
endmodule
