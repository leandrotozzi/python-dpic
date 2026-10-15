// Ex. 6: Euclid's GCD in C; an output argument reports the number of iterations.
module top;
  import "DPI-C" function int gcd(input int a, input int b, output int steps);
  initial begin
    int s, g;
    g = gcd(1071, 462, s);  $display("LOG gcd a=1071 b=462 g=%0d steps=%0d", g, s);
    g = gcd(17, 5, s);      $display("LOG gcd a=17 b=5 g=%0d steps=%0d", g, s);
    g = gcd(8, 0, s);       $display("LOG gcd a=8 b=0 g=%0d steps=%0d", g, s);
    $finish;
  end
endmodule
