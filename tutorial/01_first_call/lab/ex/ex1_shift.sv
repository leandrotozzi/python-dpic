// Ex. 12.1 (book): shift_c(i, n): n > 0 shifts left, n < 0 shifts right, n == 0 returns i.
module top;
  import "DPI-C" pure function int unsigned shift_c(input int unsigned i, input int n);
  int errors = 0;
  task automatic t(int unsigned i, int n, int unsigned exp);
    int unsigned got = shift_c(i, n);
    $display("LOG shift i=%h n=%0d got=%h", i, n, got);
    if (got !== exp) begin errors++; $display("FAIL exp=%h", exp); end
  endtask
  initial begin
    t(32'h0000_00F0,   4, 32'h0000_0F00);
    t(32'h0000_00F0,  -4, 32'h0000_000F);
    t(32'h0000_00F0,   0, 32'h0000_00F0);
    t(32'h8000_0001,   1, 32'h0000_0002);   // MSB falls off
    t(32'h8000_0001,  -1, 32'h4000_0000);   // logical, not arithmetic: unsigned
    t(32'hFFFF_FFFF,  32, 32'h0000_0000);   // C: shifting by >= 32 is UB, the C code must clamp
    t(32'hFFFF_FFFF, -40, 32'h0000_0000);
    if (errors == 0) $display("PASS ex1"); else $display("FAIL ex1");
    $finish;
  end
endmodule
