// Sample 12.8 rewritten as a module, then instantiated twice (what §12.2.2 warns about).
import "DPI-C" function void counter7(output bit [6:0] out, input bit [6:0] in,
                                      input bit reset, load);

module cnt_static #(parameter bit [6:0] INIT = 0) (input bit clk, reset, load);
  bit [6:0] out;
  always @(posedge clk) begin
    counter7(out, INIT, reset, load);       // every instance calls the SAME C function
    $display("LOG static t=%0t inst=%m out=%0d", $time, out);
  end
endmodule

module top;
  bit clk, reset, load;
  always #10 clk = ~clk;
  cnt_static #(120) u1 (.*);                // book values: i1 = 120 ...
  cnt_static #(10)  u2 (.*);                // ... and i2 = 10
  initial begin
    if ($test$plusargs("hold_reset")) reset = 1;   // exercise T6: reset held for the whole run
    @(negedge clk) load = 1;                // both load at the next posedge
    @(negedge clk) load = 0;                // then both count
    repeat (2) @(negedge clk);
    $finish;
  end
endmodule
