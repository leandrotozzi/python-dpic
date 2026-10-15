`timescale 1ns/1ns
// Exported task that waits: directly (#, @) or through a nested task. Verilator 5.052 refuses all three?
module top;
  import "DPI-C" context task c_task();
  export "DPI-C" task sv_task;
  bit clk;
  always #5 clk = ~clk;
  task inner();
    #5;
  endtask
  task sv_task();
`ifdef AT
    @(posedge clk);
`elsif NESTED
    inner();
`else
    #5;
`endif
    $display("LOG sv done t=%0t", $time);
  endtask
  initial begin
    c_task();
    $finish;
  end
endmodule
