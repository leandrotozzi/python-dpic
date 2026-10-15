// Step 07, experiment "errors": Python exception -> traceback text -> SV $error.
// Also: reference counting (leak per call) measured with sys.getallocatedblocks().
import "DPI-C" function int  err_init();
import "DPI-C" function void err_fin();
import "DPI-C" context function int err_divide(input int a, input int b, output int q);
import "DPI-C" function int  err_stale();
import "DPI-C" function int  rc_blocks_per_call(input int n, input int leak);
import "DPI-C" function void rc_immortal();

module top;
  int q, rc, n_py_errors;
  export "DPI-C" function sv_py_error;
  function void sv_py_error(string where, string text);
    n_py_errors++;
    $display("LOG sv_py_error n=%0d where=%s", n_py_errors, where);
    $display("%s", text);
  endfunction

  initial begin
    void'(err_init());
    rc = err_divide(7, 2, q);  $display("LOG divide ok rc=%0d q=%0d", rc, q);
    rc = err_divide(7, 0, q);  $display("LOG divide zero rc=%0d", rc);
    $display("LOG stale rc=%0d", err_stale());
    $display("LOG leak none=%0d", rc_blocks_per_call(1000, 0));
    $display("LOG leak leaky=%0d", rc_blocks_per_call(1000, 1));
    rc_immortal();
    if (n_py_errors != 1) $error("expected exactly one python error, got %0d", n_py_errors);
    $display("LOG errors total=%0d", n_py_errors);
    $finish;
  end
  final err_fin();
endmodule
