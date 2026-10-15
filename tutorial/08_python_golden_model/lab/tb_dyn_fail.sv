// Expected to FAIL in Verilator 5.052: a dynamic array as the actual of a DPI open array.
module top;
  import golden_pkg::*;
  byte unsigned d[];
  initial begin
    d = new[4];
    $display("%h", crc32_msg(d, 4));
  end
endmodule
