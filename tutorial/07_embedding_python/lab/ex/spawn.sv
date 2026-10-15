// Ex: Spear §12.9 (Samples 12.51-12.52) runs another language through system().
// Compare its cost per call with an embedded-interpreter call.
import "DPI-C" function int  call_cmd(input string cmd);
import "DPI-C" function real spawn_us(input int n);
import "DPI-C" function real embed_us(input int n);
module top;
  initial begin
    $display("LOG spawn rc=%0d", call_cmd("python3 -c 'import sys; sys.exit(3)'"));
    $display("LOG cost spawn_us=%0.0f", spawn_us(5));
    $display("LOG cost embed_us=%0.3f", embed_us(100000));
    $finish;
  end
endmodule
