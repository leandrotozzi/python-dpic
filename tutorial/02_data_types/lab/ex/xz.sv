// Exercise 11: count X/Z bits of a 4-state vector. In Verilator (2-state) the answer is always 0.
import "DPI-C" function int c_count_xz(input logic [39:0] v);
module top;
  logic [39:0] v = 40'hzz_xxxx_0001;
  initial begin
    $display("LOG ex_xz verilator=%0d", c_count_xz(v));
    $finish;
  end
endmodule
