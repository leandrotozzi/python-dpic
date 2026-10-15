// Ex: evaluate a Python expression from SV; Python errors become $error with the traceback.
import "DPI-C" function int py_eval_init();
import "DPI-C" context function int py_eval(input string expr, output real r);
import "DPI-C" function void py_eval_fin();
module top;
  real r;
  int  rc;
  export "DPI-C" function sv_py_error;
  function void sv_py_error(string text);
    $error("python: %s", text);
  endfunction
  initial begin
    void'(py_eval_init());
    rc = py_eval("math.sqrt(2) * 2**10", r);  $display("LOG eval1 rc=%0d r=%0.6f", rc, r);
    rc = py_eval("sum(range(101))", r);        $display("LOG eval2 rc=%0d r=%0.1f", rc, r);
    rc = py_eval("1/0", r);                    $display("LOG eval3 rc=%0d", rc);
    rc = py_eval("'abc'", r);                  $display("LOG eval4 rc=%0d", rc);
    $display("LOG eval done");
    $finish;
  end
  final begin
    py_eval_fin();
    $display("LOG eval final ran");
  end
endmodule
