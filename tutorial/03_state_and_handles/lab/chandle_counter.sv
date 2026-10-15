// Sample 12.10 as modules: each instance owns a chandle to its own C/C++ counter object.
// The same SV file links against chandle_counter.c OR counter7.cpp (§12.3.1: "looks the same").
import "DPI-C" function chandle counter7_new();
import "DPI-C" function void    counter7_free(input chandle inst);
import "DPI-C" function int     counter7_live();
import "DPI-C" function int     counter7(input chandle inst, output bit [6:0] out,
                                         input bit [6:0] in, input bit reset, load);

module cnt_inst #(parameter bit [6:0] INIT = 0) (input bit clk, reset, load);
  chandle   inst;                 // null until constructed
  bit [6:0] out;
  initial inst = counter7_new();  // one C object per module instance
  final begin                     // SV has no destructor: free it yourself
    counter7_free(inst);
    $display("LOG final inst=%m live_after_free=%0d", counter7_live());
  end
  always @(posedge clk) begin
    void'(counter7(inst, out, INIT, reset, load));
    $display("LOG inst t=%0t inst=%m out=%0d", $time, out);
  end
endmodule

module top;
  bit clk, reset, load;
  chandle nobody;                 // never assigned
  bit [6:0] o;
  always #10 clk = ~clk;
  cnt_inst #(120) u1 (.*);
  cnt_inst #(10)  u2 (.*);
  initial begin
    $display("LOG null default_is_null=%0d", nobody == null);
    if ($test$plusargs("null"))   // pass a null chandle on purpose: the C side must defend itself
      $display("LOG null rc=%0d", counter7(nobody, o, 0, 0, 0));
    @(negedge clk) load = 1;
    @(negedge clk) load = 0;
    repeat (2) @(negedge clk);
    $display("LOG live before_final=%0d", counter7_live());
    $finish;
  end
  final $display("LOG live top_final=%0d", counter7_live());  // order of final blocks is unspecified
endmodule
