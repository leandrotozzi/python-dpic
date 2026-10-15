// Step 01: the simulator cannot see C code. Here SV and C disagree on types.
module top;
  // SV says: 64-bit argument, 64-bit result
  import "DPI-C" function longint negate(input longint v);
  initial begin
    longint v = 64'h1_0000_0005;     // 4294967301
    $display("LOG mismatch v=%0d negate=%0d expected=%0d", v, negate(v), -v);
    $finish;
  end
endmodule
