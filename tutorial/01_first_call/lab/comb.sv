// Step 01: an import called from combinational logic runs whenever the simulator re-evaluates it,
// not once per "change you meant". ping_raw() counts calls (pure.c).
module top;
  import "DPI-C" function int ping_raw(input int x);
  import "DPI-C" function int calls();
  logic clk = 0;
  int x = 0, y, z;
  always_comb y = ping_raw(x);          // evaluated when x changes
  assign z = ping_raw(x + 1);           // a second call site, same input
  always #5 clk = ~clk;
  always @(posedge clk) x <= x + 1;     // x changes 10 times below
  initial begin
    #1 $display("LOG comb t=1 calls=%0d", calls());
    #100 $display("LOG comb t=101 calls=%0d x=%0d y=%0d z=%0d", calls(), x, y, z);
    $finish;
  end
endmodule
