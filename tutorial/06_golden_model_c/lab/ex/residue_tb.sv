// Exercise 8: a model-free CRC check. Append the CRC (little-endian) to a message and the CRC of
// the whole thing is the constant residue 0x2144DF1C, whatever the message.
module top;
  import golden_pkg::*;
  initial begin
    byte unsigned b[64];
    int bad = 0;
    for (int t = 0; t < 1000; t++) begin
      int len = $urandom_range(60);
      int unsigned c;
      for (int i = 0; i < len; i++) b[i] = $urandom;
      c = crc32_msg(b, len);
      for (int k = 0; k < 4; k++) b[len + k] = c[8*k +: 8];
      if (crc32_msg(b, len + 4) != 32'h2144DF1C) bad++;
    end
    $display("LOG residue trials=1000 bad=%0d", bad);
    if (bad == 0) $display("PASS residue"); else $display("FAIL residue");
    $finish;
  end
endmodule
