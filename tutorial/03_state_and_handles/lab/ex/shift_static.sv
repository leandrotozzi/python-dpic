// Ex. 12.2 test: load, shift the register left/right, out-of-range shift.
import "DPI-C" function int unsigned shift_c(input int unsigned i, input int n, input bit ld);
module top;
  initial begin
    $display("LOG ex2 a=%h", shift_c(32'h0000_00F0, 4, 1));   // load F0<<4 = F00
    $display("LOG ex2 b=%h", shift_c(0, -8, 0));              // reg >> 8 = F
    $display("LOG ex2 c=%h", shift_c(0, 0, 0));               // unchanged = F
    $display("LOG ex2 d=%h", shift_c(32'h8000_0001, 0, 1));   // load as is
    $display("LOG ex2 e=%h", shift_c(0, 1, 0));               // MSB falls off: 2
    $display("LOG ex2 f=%h", shift_c(0, 40, 0));              // |n| >= 32 -> 0
    $finish;
  end
endmodule
