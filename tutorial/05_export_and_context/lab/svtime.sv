// H.13: svGetTime / svGetTimeUnit / svGetTimePrecision let C read simulation time without an
// exported function. The top runs at 1ns/1ps; `sub` declares its own timeunit 1us.
`timescale 1ns/1ps
module top;
  import "DPI-C" context function void c_time(input string tag);
  sub s();
  initial begin
    #25   c_time("t25");
    #1.5  c_time("t26_5");
    #10   $finish;                       // after sub fires at 30 ns
  end
endmodule
module sub;
  timeunit 1us; timeprecision 1ps;
  import "DPI-C" context function void c_time_sub(input string tag);
  initial #0.03 c_time_sub("sub30ns");          // 0.03 us = 30 ns
endmodule
