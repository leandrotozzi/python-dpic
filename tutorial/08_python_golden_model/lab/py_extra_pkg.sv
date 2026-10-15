// Python-only extras of step 08, on top of the shared contract (06_golden_model_c/lab/golden_pkg.sv).
// Implemented in golden_py.c. Testbenches that must also run on the C backend do not import this.
package py_extra_pkg;
  // wide arithmetic: 100 x 100 -> 200 bits (not word aligned on purpose)
  import "DPI-C" function void py_mul_wide(input bit [99:0] a, input bit [99:0] b, output bit [199:0] p);
  // any module.func(int64...) -> int64, no C change per function
  import "DPI-C" function longint py_call_i64(input string mod, input string func, input longint args[]);
  // bug injection at run time (GOLDEN_BUG=<name> in the environment does the same at startup)
  import "DPI-C" function void    py_set_bug(input string name);
  // text of the first Python failure since the last call, "" if none
  import "DPI-C" function string  py_last_error();
endpackage
