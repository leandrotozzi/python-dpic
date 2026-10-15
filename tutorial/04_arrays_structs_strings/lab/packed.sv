// Samples 12.26-12.27 (corrected) + the canonical accessors for packed elements.
// An open array has ONE packed dimension (any width) and one or more unpacked ones.
import "DPI-C" function void view_pack(input bit [63:0] b64[]);
import "DPI-C" function void wide_sum(input bit [99:0] w[], output bit [99:0] total);
import "DPI-C" function void put_wide(inout bit [99:0] w[]);
import "DPI-C" function int  layout(input bit [7:0] b[], input bit [12:0] s[], input bit [63:0] q[], input bit [99:0] w[]);
import "DPI-C" function void logic_get(input logic [7:0] l[], output int aval, output int bval);
import "DPI-C" function int  raw8(input bit [7:0] b[]);
import "DPI-C" function int  bits(input bit m[]);

module top;
  bit [1:0][0:3][6:-1] bpack[9:1];     // 2*4*8 = 64 bits per element, like the formal
  bit [99:0] w[3];
  bit [99:0] total;
  bit [7:0]  b8[4];
  bit [12:0] s13[4];
  bit [63:0] q64[4];
  logic [7:0] l8[2];
  bit         m[5] = '{1, 0, 1, 1, 0};
  int av, bv;
  initial begin
    foreach (bpack[i]) bpack[i] = i;
    bpack[2] = 64'h12345678_90abcdef;
    $display("LOG sv bpack2=%h bpack2_0=%h bpack2_0_0=%h", bpack[2], bpack[2][0], bpack[2][0][0]);
    view_pack(bpack);
    w[0] = 100'h1_0000_0000_0000_0000_0000_0001;   // bit 96 and bit 0
    w[1] = 100'h2_0000_0000_0000_0000_0000_0002;
    w[2] = 100'h0_ffff_ffff_0000_0000_ffff_ffff;
    wide_sum(w, total);
    $display("LOG wide_sum total=%h expect=%h", total, w[0] + w[1] + w[2]);
    put_wide(w);
    $display("LOG put_wide w1=%h", w[1]);
    $display("LOG layout code=%0d", layout(b8, s13, q64, w));
    l8[1] = 8'hA5;
    logic_get(l8, av, bv);
    $display("LOG logic_get aval=%h bval=%h", av, bv);
    b8 = '{8'h11, 8'h22, 8'h33, 8'h44};
    $display("LOG raw8 elem0=%h", raw8(b8));
    $display("LOG bits ones=%0d", bits(m));
    $finish;
  end
endmodule
