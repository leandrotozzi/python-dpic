// Experiment "zlit": a 1'bz literal as a DPI argument. Verilator rejects it (tristate), see run.sh.
import "DPI-C" function logic rt_logic(input logic v);
module top; initial $display("%b", rt_logic(1'bz)); endmodule
