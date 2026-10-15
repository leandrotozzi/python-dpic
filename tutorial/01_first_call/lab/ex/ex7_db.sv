// Ex. 7: dB -> linear gain with libm pow/log10 (no wrapper), versus SV's own ** operator.
module top;
  import "DPI-C" pure function real pow(input real x, input real y);
  import "DPI-C" pure function real log10(input real x);
  initial begin
    real c = pow(10.0, -3.0 / 20.0), s = 10.0 ** (-3.0 / 20.0);
    $display("LOG db c=%0.10f sv=%0.10f same=%0d back=%0.6f", c, s, c == s, 20.0 * log10(c));
    $finish;
  end
endmodule
