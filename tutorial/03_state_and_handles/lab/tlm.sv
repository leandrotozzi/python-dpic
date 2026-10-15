// Sample 12.17 (+ explicit free): an SV class hides the chandle. SV garbage-collects the SV
// object, but it knows nothing about the C++ object behind the chandle.
import "DPI-C" function chandle counter7_new();
import "DPI-C" function void    counter7_delete(input chandle inst);
import "DPI-C" function void    counter7_count(input chandle inst);
import "DPI-C" function void    counter7_load(input chandle inst, input bit [6:0] i);
import "DPI-C" function void    counter7_reset(input chandle inst);
import "DPI-C" function int     counter7_get(input chandle inst);
import "DPI-C" function int     counter7_live();

class Counter7;
  static int n_wrappers;           // SV-side static: shared by every Counter7 object
  local chandle inst;              // per-object: which C++ object this wrapper owns
  function new();
    inst = counter7_new();
    n_wrappers++;
  endfunction
  function void free();            // the "destructor" SV does not have
    if (inst != null) counter7_delete(inst);
    inst = null;                   // second free() / use after free becomes a no-op / error
  endfunction
  function void count();               counter7_count(inst);  endfunction
  function void load(bit [6:0] val);   counter7_load(inst, val); endfunction
  function void reset();               counter7_reset(inst);  endfunction
  function bit [6:0] get();            return 7'(counter7_get(inst)); endfunction
  function bit alive();                return inst != null;   endfunction
endclass

module top;
  Counter7 c1, c2, tmp;
  initial begin
    c1 = new;
    c1.reset();
    c1.load(126);
    c1.count(); c1.count();                             // 126 -> 127 -> 0 (7 bits)
    $display("LOG tlm get=%0d", c1.get());

    // shallow copy: the chandle is copied, the C++ object is not -> both wrappers drive ONE counter
    c2 = new c1;
    c2.count();
    $display("LOG shallow c1=%0d c2=%0d live=%0d wrappers=%0d", c1.get(), c2.get(),
             counter7_live(), Counter7::n_wrappers);    // `new c1` does not run new()

    // leak: 100 wrappers dropped without free(); SV reclaims them, C++ does not
    for (int k = 0; k < 100; k++) begin tmp = new; tmp.count(); end
    tmp = null;
    $display("LOG leak live=%0d wrappers=%0d", counter7_live(), Counter7::n_wrappers);

    // no leak: free() before dropping the handle
    for (int k = 0; k < 100; k++) begin tmp = new; tmp.count(); tmp.free(); end
    $display("LOG noleak live=%0d", counter7_live());

    c1.free();                                          // frees the object c2 ALSO points to
    $display("LOG after_free c1_alive=%0d c2_alive=%0d live=%0d", c1.alive(), c2.alive(), counter7_live());
    $finish;
  end
endmodule
