// Step 07, experiment "threads": who calls DPI when Verilator runs with --threads N?
// Eight independent lanes each call Python once per clock.
`ifdef PURE
import "DPI-C" pure function int th_call(input int x);
`else
import "DPI-C" function int th_call(input int x);
`endif
import "DPI-C" function void th_init();
import "DPI-C" function void th_fin();

module top;
  logic clk = 0;
  int acc [8];
  for (genvar g = 0; g < 8; g++) begin : lane
    always_ff @(posedge clk) acc[g] <= th_call(acc[g] + g);
  end
  initial begin
    th_init();
    repeat (400) begin #5 clk = 1; #5 clk = 0; end
    $display("LOG lanes acc0=%0d acc7=%0d", acc[0], acc[7]);
    $finish;
  end
  final th_fin();
endmodule
