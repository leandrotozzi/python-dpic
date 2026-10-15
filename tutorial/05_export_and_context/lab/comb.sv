`timescale 1ns/1ns
// DPI calls in combinational logic: how many times does C run per input change?
module top;
  import "DPI-C" pure function int sq_pure(int x);
  import "DPI-C"      function int sq_gen(int x);
  import "DPI-C" function int calls_pure();
  import "DPI-C" function int calls_gen();
  int x, yp, yg, z;
  assign yp = sq_pure(x);
  assign yg = sq_gen(x);
  always_comb z = yp + 1;
  initial begin
    for (int i = 1; i <= 5; i++) #1 x = i;   // 5 changes of x
    #1 $display("LOG comb pure_calls=%0d gen_calls=%0d yp=%0d yg=%0d", calls_pure(), calls_gen(), yp, yg);
    $finish;
  end
endmodule
