// Experiment "counter4": Spear Samples 12.11/12.12, the 7-bit counter with 4-state (logic) ports.
// The C model rejects X/Z on its inputs. A 4-state simulator would print the errors; Verilator is 2-state.
import "DPI-C" function chandle counter7_new();
import "DPI-C" function void counter7(input chandle inst, output logic [6:0] out,
                                      input logic [6:0] in, input logic reset, load);
module top;
  chandle c;
  logic [6:0] out = 0, in;
  logic reset, load;                       // left uninitialized on purpose: X in a 4-state simulator
  initial begin
    c = counter7_new();
    counter7(c, out, 7'd0, reset, 1'b0);    // reset is X (4-state) / 0 (Verilator)
    $display("LOG c4 step=xreset out=%0d", out);
    in = 7'b000_zzxx;
    counter7(c, out, in, 1'b0, 1'b1);       // load a value with Z/X bits
    $display("LOG c4 step=xload out=%0d", out);
    counter7(c, out, 7'd5, 1'b1, 1'b0);     // clean reset
    $display("LOG c4 step=reset out=%0d", out);
    $finish;
  end
endmodule
