// Ex. 11: a first golden model. C popcount (compiler builtin) vs SV $countones on random data.
module top;
  import "DPI-C" pure function int popcount32(input int unsigned x);
  initial begin
    int errors = 0;
    int unsigned x;
    for (int k = 0; k < 10000; k++) begin
      x = (k < 2) ? (k == 0 ? 32'h0 : 32'hFFFF_FFFF) : $urandom;   // corners first
      if (popcount32(x) != $countones(x)) begin
        errors++; $display("FAIL x=%h c=%0d sv=%0d", x, popcount32(x), $countones(x));
      end
    end
    $display("LOG popcount n=10000 errors=%0d", errors);
    if (errors == 0) $display("PASS ex11"); else $display("FAIL ex11");
    $finish;
  end
endmodule
