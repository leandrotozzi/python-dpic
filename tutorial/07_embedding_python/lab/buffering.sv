// Step 07, experiment "buffering": interleave $display and Python print() with stdout
// redirected to a file (as in any regression). Who prints first?
import "DPI-C" function int  buf_init(input int unbuffered);
import "DPI-C" function void buf_say(input int i, input int py_flush, input int c_flush);
import "DPI-C" function void buf_fin();

module top;
  int py_flush, c_flush, unbuffered;
  initial begin
    void'($value$plusargs("pyflush=%d", py_flush));
    void'($value$plusargs("cflush=%d", c_flush));
    void'($value$plusargs("unbuffered=%d", unbuffered));
    void'(buf_init(unbuffered));
    for (int i = 0; i < 3; i++) begin
      $display("SV %0d", i);
      buf_say(i, py_flush, c_flush);
    end
    $finish;
  end
  final buf_fin();
endmodule
