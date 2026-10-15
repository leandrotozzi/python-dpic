// Sample 12.30-12.31 + string directions. SV string <-> C const char*.
import "DPI-C" function int    c_strlen(input string s);
import "DPI-C" function string hex_static(input int v);    // Sample 12.30: static buffer
import "DPI-C" function string hex_ring(input int v);      // Sample 12.31: ring of buffers
import "DPI-C" function void   name_of(input int code, output string name);
import "DPI-C" function void   upcase(inout string s);
import "DPI-C" function void   keep(input string s);       // stores a COPY for later
import "DPI-C" function string kept();

module top;
  string s, a, b, n;
  initial begin
    $display("LOG strlen n=%0d empty=%0d", c_strlen("hello, DPI"), c_strlen(""));
    // Two calls inside one expression: does SV copy the first result before the second call?
    $display("LOG static_two a=%s b=%s", hex_static(32'h1111), hex_static(32'h2222));
    a = hex_static(32'hAAAA);
    b = hex_static(32'hBBBB);                               // overwrites C's buffer...
    $display("LOG static_vars a=%s b=%s", a, b);           // ...but a was already copied
    $display("LOG ring a=%s b=%s", hex_ring(1), hex_ring(2));
    name_of(1, n);
    $display("LOG name_of n=%s", n);
    s = "mixed Case";
    upcase(s);
    $display("LOG upcase s=%s", s);
    s = "first";
    keep(s);
    s = "changed";                                          // SV reuses/frees its storage
    $display("LOG keep kept=%s", kept());
    $finish;
  end
endmodule
