`timescale 1ns/1ps
// Python backend only: the generic bridge, chandle lifetime, and how each failure reaches SV.
module top;
  import golden_pkg::*;                                // step 06's contract
  import py_extra_pkg::*;                              // py_call_i64, py_set_bug, py_last_error
  longint none[1] = '{0}, two[2] = '{40, 2};
  chandle h;
  shortint coef[8] = '{16'sh7fff, 0, 0, 0, 0, 0, 0, 0}, xs[4] = '{1, 2, 3, 4}, ys[4];

  function automatic void show(string tag, longint v);
    $display("LOG %s value=%0d err=%s", tag, v, py_last_error());
  endfunction

  initial begin
    // generic bridge: any module.func, args as an open array of longint
    show("call_operator_add", py_call_i64("operator", "add", two));    // stdlib, no glue code
    show("call_math_gcd", py_call_i64("math", "gcd", two));
    // chandle lifetime: Fir8.live counts Python instances
    show("live_before", py_call_i64("golden", "fir_live", none));
    h = fir8_new(coef);
    show("live_after_new", py_call_i64("golden", "fir_live", none));
    fir8_free(h);
    show("live_after_free", py_call_i64("golden", "fir_live", none));
    // failures: each one becomes a message, the call returns 0, the simulation goes on
    show("missing_module", py_call_i64("no_such_module", "f", none));
    show("missing_func", py_call_i64("golden", "nope", none));
    show("raises", py_call_i64("golden", "fails", none));
    show("overflow", py_call_i64("golden", "big", none));
    // a model that keeps the memoryview: the bridge sees refcount > 1 and reports it
    py_set_bug("keep_memoryview");
    h = fir8_new(coef);
    fir8_block(h, xs, ys, 4);
    show("keep_memoryview", 0);
    fir8_free(h);
    // a model that keeps a numpy view: undetected, Python now aliases live simulator memory
    py_set_bug("none");
    py_set_bug("keep_numpy");
    h = fir8_new(coef);
    fir8_block(h, xs, ys, 4);
    show("keep_numpy", 0);
    xs[0] = 1234;                                                    // SV writes, no DPI call involved
    show("kept0_after_sv_write", py_call_i64("golden", "kept0", none));
    fir8_free(h);
    $error("scoreboard: %0d model errors", 6);                         // what does Verilator do next?
    $display("LOG after_error reached=1");
    $finish;
  end
endmodule
