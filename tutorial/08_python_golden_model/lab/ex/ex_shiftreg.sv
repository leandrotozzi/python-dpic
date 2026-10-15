`timescale 1ns/1ps
// Ex. 12.2-12.6 with Python objects behind chandles: two Shift instances, each with its own register.
module top;
  import py_extra_pkg::*;                        // for py_last_error()
  import "DPI-C" function chandle py_new(input string mod, input string cls, input longint args[]);
  import "DPI-C" function longint py_call_method_i64(input chandle obj, input string method, input longint args[]);
  import "DPI-C" function void    py_free(input chandle obj);
  chandle s1, s2;
  longint none[1] = '{0}, a1[1], a3[3];      // no '{...} literal as an open-array actual in Verilator
  initial begin
    a1 = '{32'h0000_00F0}; s1 = py_new("ex_models", "Shift", a1);    // Ex. 12.5: initial value
    a1 = '{32'h8000_0001}; s2 = py_new("ex_models", "Shift", a1);
    a3 = '{1, 4, 1};  $display("LOG shiftreg s1_load=%h",   32'(py_call_method_i64(s1, "shift", a3)));  // load 1<<4
    a3 = '{0, 4, 0};  $display("LOG shiftreg s1_shift=%h",  32'(py_call_method_i64(s1, "shift", a3)));  // reg<<4
    a3 = '{0, -1, 0}; $display("LOG shiftreg s2_shift=%h",  32'(py_call_method_i64(s2, "shift", a3)));  // reg>>1
    a3 = '{0, 1, 0};  $display("LOG shiftreg s2_shift2=%h", 32'(py_call_method_i64(s2, "shift", a3)));  // reg<<1
    $display("LOG shiftreg total_calls=%0d", py_call_method_i64(s1, "total_calls", none));               // Ex. 12.4
    $display("LOG shiftreg err=%s", py_last_error());
    py_free(s1); py_free(s2);
    $finish;
  end
endmodule
