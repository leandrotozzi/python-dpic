`timescale 1ns/1ns
// Exported task WITHOUT timing controls, called from an imported context task: legal and supported.
module top;
  import "DPI-C" context task c_task(int n);
  export "DPI-C" task sv_task;
  int calls;
  task sv_task(input int i, output int o);
    calls++;
    o = i * 10;
  endtask
  initial begin
    c_task(3);
    $display("LOG sv calls=%0d t=%0t", calls, $time);
    $finish;
  end
endmodule
