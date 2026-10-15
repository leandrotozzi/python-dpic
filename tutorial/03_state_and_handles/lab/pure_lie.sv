import "DPI-C" pure function int bump(input int x);       // a lie: bump() counts its calls
import "DPI-C" function int bump_calls();

module top;
  int a, b, c;
  initial begin
    a = bump(1);           // used result
    b = bump(1);           // same argument: may be merged with the first (common subexpression)
    void'(bump(5));        // result discarded: a pure call with no effect may be removed
    for (int k = 0; k < 10; k++) c = bump(k);   // only the last value of c is ever used
    $display("LOG pure a=%0d b=%0d c=%0d calls=%0d", a, b, c, bump_calls());
    $finish;
  end
endmodule
