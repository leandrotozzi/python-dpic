`timescale 1ns/1ns
// Exercise: a C model reports mismatches THROUGH SV, so they carry $time, the SV error count
// and the simulator's severity handling (+ a C-side "where am I" via svGetCallerInfo).
module top;
  import "DPI-C" context function void c_check(int got, int exp);
  export "DPI-C" function sv_report;
  function void sv_report(string where, string msg);
    $error("[C model @ %s] %s", where, msg);
  endfunction
  initial begin
    #5  c_check(3, 3);
    #5  c_check(4, 5);
    #10 c_check(7, 9);
    $finish;
  end
  final $display("LOG report done");
endmodule
