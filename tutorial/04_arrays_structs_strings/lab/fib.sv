// Samples 12.18-12.21: fixed-size unpacked arrays, 2-state and 4-state.
// The array lives in SV; C only receives a pointer to its storage.
import "DPI-C" function void fib2(output bit   [31:0] data[20]);
import "DPI-C" function void fib4(output logic [31:0] data[20]);
import "DPI-C" function void fib4_bad(output logic [31:0] data[20]);
import "DPI-C" function int  sum8(input int v[8]);           // int elements: plain int*
import "DPI-C" function void bytes_in(input byte b[4], output int packed_le);

module top;
  bit   [31:0] d2[20];
  logic [31:0] d4[20];
  int          v[8];
  byte         b[4] = '{8'h11, 8'h22, 8'h33, 8'h44};
  int          le;
  initial begin
    fib2(d2);
    fib4(d4);
    foreach (v[i]) v[i] = i * i;                              // 0 1 4 ... 49 -> 140
    $display("LOG fib2 d0=%0d d1=%0d d19=%0d", d2[0], d2[1], d2[19]);
    $display("LOG fib4 d19=%0d unknown=%0d", d4[19], $isunknown(d4[19]));
    fib4_bad(d4);
    $display("LOG fib4_bad d2=%h unknown=%0d", d4[2], $isunknown(d4[2]));
    $display("LOG sum8 sum=%0d", sum8(v));
    bytes_in(b, le);
    $display("LOG bytes_in le=%h", le);
    $finish;
  end
endmodule
