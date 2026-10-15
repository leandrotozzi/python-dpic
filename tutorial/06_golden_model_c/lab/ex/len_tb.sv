// Exercise 12: a length larger than the buffer. golden.c refuses (abort) instead of reading past it.
module top;
  import golden_pkg::*;
  initial begin
    byte unsigned b[256];
    $display("LOG len calling crc32_msg(b, 300)");
    $display("LOG len result=%h", crc32_msg(b, 300));   // never printed
    $finish;
  end
endmodule
