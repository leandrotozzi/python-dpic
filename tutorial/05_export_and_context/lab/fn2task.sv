`timescale 1ns/1ns
// An imported FUNCTION calling an exported TASK. IEEE 1800 clause 35 forbids it (a function may not
// call a task, and that holds across the DPI boundary). Does Verilator notice?
module top;
  import "DPI-C" context function void f_calls_task();
  export "DPI-C" task sv_wait;
  task sv_wait();
    $display("LOG sv waited t=%0t", $time);
  endtask
  initial begin
    f_calls_task();
    $display("LOG sv after t=%0t", $time);
    $finish;
  end
endmodule
