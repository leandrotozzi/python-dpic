// Expected to FAIL in Verilator 5.052: logic signed [15:0] c[8] passed to `input shortint coef[8]`.
module top;
  import golden_pkg::*;
  logic signed [15:0] c[8];
  chandle h;
  initial h = fir8_new(c);
endmodule
