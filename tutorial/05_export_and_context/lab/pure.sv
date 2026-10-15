`timescale 1ns/1ns
// Does `pure` change how many times C runs? Both C functions count their calls (a side effect a
// real pure function must NOT have: this is a probe of what the compiler is allowed to do).
module top;
  import "DPI-C" pure function int sq_pure(int x);
  import "DPI-C"      function int sq_gen(int x);
  import "DPI-C" function int calls_pure();
  import "DPI-C" function int calls_gen();
  int a, b, r;
  initial begin
    a = 7;
    void'(sq_pure(a));                    // result discarded
    void'(sq_gen(a));
    r = sq_pure(a) + sq_pure(a);          // same args twice in one expression
    b = sq_gen(a) + sq_gen(a);
    for (int i = 0; i < 4; i++) r += sq_pure(a);   // loop-invariant call
    for (int i = 0; i < 4; i++) b += sq_gen(a);
    $display("LOG pure calls=%0d r=%0d", calls_pure(), r);
    $display("LOG gen calls=%0d b=%0d", calls_gen(), b);
    $finish;
  end
endmodule
