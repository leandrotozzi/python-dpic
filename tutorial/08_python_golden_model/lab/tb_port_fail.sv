// Expected to FAIL: a shortint array on a `logic signed [15:0] coef [8]` port (2-state vs 4-state elements).
module top;
  logic clk, rst_n, in_valid, out_valid;
  logic signed [15:0] in_x, out_y;
  shortint coef[8];
  fir8 dut (.*);
endmodule
