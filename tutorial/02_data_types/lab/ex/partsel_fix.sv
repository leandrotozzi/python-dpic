// Exercise 7: fill bits [85:70] of a 200-bit output, every other bit 0.
import "DPI-C" function void c_scratch200(input bit [199:0] v);     // leaves junk on the stack
import "DPI-C" function void c_put16(output bit [199:0] w, input bit [15:0] f, input int lsb);
module top;
  bit [199:0] w;
  initial begin
    c_scratch200({200{1'b1}});
    c_put16(w, 16'hBEEF, 70);
    $display("LOG ex_partsel ok=%0d", w == (200'hBEEF << 70));
    if (w == (200'hBEEF << 70)) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
