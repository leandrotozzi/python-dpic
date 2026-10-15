// Experiment "dir": input / output / inout semantics as Verilator implements them.
import "DPI-C" function void c_peek_out (output int o);                    // reads *o before writing it
import "DPI-C" function void c_skip_out (output int o, output bit [39:0] v); // never writes its outputs
import "DPI-C" function void c_inc_inout(inout int io, inout bit [39:0] v);
import "DPI-C" function void c_alias    (input int i, output int o);        // called as c_alias(x, x)
import "DPI-C" function void c_bad_bit  (output bit b, output logic l);      // writes 0xFE into 1-bit outputs
import "DPI-C" function void c_scratch  (input bit [39:0] v);               // leaves a pattern in the 40-bit temp

module top;
  int o = 77, io = 10, x = 5;
  bit [39:0] v = 40'hAA_0000_0001, vv = 40'h00_FFFF_FFFF;
  bit b; logic l;
  initial begin
    c_peek_out(o);
    $display("LOG peek o=%0d", o);
    o = 77;
    c_scratch(40'h12_3456_7890);
    c_skip_out(o, v);
    $display("LOG skip o=%0d v=%h", o, v);
    c_inc_inout(io, vv);
    $display("LOG inout io=%0d vv=%h", io, vv);
    c_alias(x, x);
    $display("LOG alias x=%0d", x);
    c_bad_bit(b, l);
    $display("LOG badbit b=%b l=%b b_eq1=%0d b_plus0=%0d", b, l, b == 1'b1, b + 2'd0);
    $finish;
  end
endmodule
