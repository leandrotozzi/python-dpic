// Experiment "vec": packed vectors through DPI (canonical representation, Annex H.7.7 / H.10).
import "DPI-C" function void c_dump    (input string tag, input bit   [199:0] v, input int width);
import "DPI-C" function void c_dump40  (input bit [39:0] v);
import "DPI-C" function void c_dump_s40(input bit signed [39:0] v);
import "DPI-C" function void c_dirty40 (output bit [39:0] v);           // C writes 1s into the unused bits
import "DPI-C" function void c_add200  (input bit [199:0] a, b, output bit [199:0] sum);
import "DPI-C" function void c_partsel (input bit [199:0] v, output bit [15:0] f, output bit [199:0] w);
import "DPI-C" function int  c_sign8   (input bit signed [7:0] v);      // SV_GET_SIGNED_BITS vs a correct sign-extend
import "DPI-C" function void c_ldump   (input logic [39:0] v);          // 4-state vector: aval/bval
import "DPI-C" function void c_lwrite  (output logic [7:0] v);          // C writes X/Z (bval=1) into the result

module top;
  bit [199:0] a, b, s, w;
  bit [39:0]  d;
  bit [15:0]  f;
  logic [39:0] l40;
  logic [7:0]  l8;
  initial begin
    // word order: word 0 holds bits [31:0]
    c_dump40(40'h12_3456_789A);
    c_dump("v200", {8'hC7, {6{32'h0}}} | 200'h1, 200);
    c_dump_s40(-40'sd2);                                     // what is in bits [63:40] of word 1?
    // dirty output: does SV mask bits 40..63 that C set?
    c_dirty40(d);
    $display("LOG dirty d=%h eq=%0d plus1=%h", d, d == 40'hFF_FFFF_FFFF, d + 40'd1);
    // 200-bit arithmetic in C, checked in SV
    a = {200{1'b1}} >> 3;  b = 200'd12345;
    c_add200(a, b, s);
    $display("LOG add200 ok=%0d", s == a + b);
    // part-select helpers
    w = '0;
    c_partsel(200'hDEAD << 100, f, w);
    $display("LOG partsel f=%h w_ok=%0d w=%h", f, w == (200'hBEEF << 70), w);
    $display("LOG sign8 m128=%0d m1=%0d p5=%0d", c_sign8(-8'sd128), c_sign8(-8'sd1), c_sign8(8'sd5));
    // 4-state: X/Z inside a vector, and C writing X/Z back
    l40 = 40'h12_3456_78zx;
    c_ldump(l40);
    c_lwrite(l8);
    $display("LOG lwrite l8=%b", l8);
    $finish;
  end
endmodule
