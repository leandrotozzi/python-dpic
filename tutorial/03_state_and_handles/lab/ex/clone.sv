// T8 solution: copy() builds a NEW wrapper around a NEW C++ object (deep copy).
import "DPI-C" function chandle counter7_new();
import "DPI-C" function chandle counter7_clone(input chandle inst);
import "DPI-C" function void    counter7_delete(input chandle inst);
import "DPI-C" function void    counter7_count(input chandle inst);
import "DPI-C" function void    counter7_load(input chandle inst, input bit [6:0] i);
import "DPI-C" function int     counter7_get(input chandle inst);
import "DPI-C" function int     counter7_live();

class Counter7;
  local chandle inst;
  function new(chandle from = null);           // null: fresh object; else adopt `from`
    inst = (from == null) ? counter7_new() : from;
  endfunction
  function Counter7 copy();  copy = new(counter7_clone(inst)); endfunction
  function void free();      if (inst != null) counter7_delete(inst); inst = null; endfunction
  function void count();     counter7_count(inst); endfunction
  function void load(bit [6:0] v); counter7_load(inst, v); endfunction
  function int  get();       return counter7_get(inst); endfunction
endclass

module top;
  Counter7 a, b;
  initial begin
    a = new; a.load(5);
    b = a.copy();
    b.count();
    $display("LOG clone a=%0d b=%0d live=%0d", a.get(), b.get(), counter7_live());   // 5 6 2
    a.free();
    $display("LOG clone b_after_a_free=%0d live=%0d", b.get(), counter7_live());      // 6 1
    b.free();
    $display("LOG clone live_end=%0d", counter7_live());                            // 0
    $finish;
  end
endmodule
