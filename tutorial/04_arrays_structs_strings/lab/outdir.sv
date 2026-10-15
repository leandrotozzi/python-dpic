// What does an `output` array hold where C did not write? (IEEE: undefined on entry to C.)
import "DPI-C" function void w_out(output int c[]);     // open array, output
import "DPI-C" function void w_io(inout int c[]);       // open array, inout
import "DPI-C" function void w_outf(output int c[3]);   // fixed array, output
module top;
  int a[3] = '{5, 5, 5}, b[3] = '{5, 5, 5}, f[3] = '{5, 5, 5};
  initial begin
    w_out(a); w_io(b); w_outf(f);                       // each C function writes ONLY element 1
    $display("LOG outdir out=%0d,%0d,%0d io=%0d,%0d,%0d outf0_is5=%0d outf1=%0d",
             a[0], a[1], a[2], b[0], b[1], b[2], f[0] == 5, f[1]);
    $finish;
  end
endmodule
