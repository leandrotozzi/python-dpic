// Ex. 12.1 with the shifter written in Python.
import "DPI-C" function int          ex_init();
import "DPI-C" function int unsigned shift_py(input int unsigned i, input int n, input int naive);
import "DPI-C" function void         ex_fin();
module top;
  initial begin
    void'(ex_init());
    $display("LOG shift l4=%h r4=%h z=%h l31=%h r40=%h", shift_py(32'h8000_00F1, 4, 0),
             shift_py(32'h8000_00F1, -4, 0), shift_py(32'h8000_00F1, 0, 0),
             shift_py(1, 31, 0), shift_py(32'hFFFF_FFFF, -40, 0));
    $display("LOG naive r4=%h", shift_py(32'h8000_00F1, -4, 1));
    $finish;
  end
  final ex_fin();
endmodule
