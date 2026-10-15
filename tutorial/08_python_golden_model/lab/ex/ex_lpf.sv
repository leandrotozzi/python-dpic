`timescale 1ns/1ps
// Ex. 11: the DUT is reset in the middle of the stream. The model must be reset too: Fir8R (a Fir8
// with reset()) is created with the generic py_new(), then driven by the contract's fir8_step().
// coef is logic (the DUT port type): a shortint array is not port-compatible (2- vs 4-state).
// +no_model_reset shows what the scoreboard sees when the model is not reset.
module top;
  import golden_pkg::*;
  import py_extra_pkg::*;
  import "DPI-C" function chandle py_new(input string mod, input string cls, input longint args[]);
  import "DPI-C" function longint py_call_method_i64(input chandle obj, input string method, input longint args[]);
  import "DPI-C" function void    py_free(input chandle obj);
  logic clk = 0, rst_n = 0, in_valid = 0, out_valid;
  logic signed [15:0] in_x, out_y;
  logic signed [15:0] coef[8] = '{16'sh0400, 16'sh0c00, 16'sh1800, 16'sh2400, 16'sh2400, 16'sh1800, 16'sh0c00, 16'sh0400};
  longint cargs[8], none[1] = '{0};
  fir8 dut (.*);
  always #5 clk = ~clk;
  chandle h;
  int n_err;
  initial begin
    foreach (coef[i]) cargs[i] = coef[i];
    h = py_new("ex_models", "Fir8R", cargs);
    repeat (2) @(negedge clk);
    rst_n = 1;
    for (int n = 0; n < 600; n++) begin
      if (n == 300) begin                                          // mid-stream reset
        rst_n = 0; @(negedge clk); rst_n = 1;
        if (!$test$plusargs("no_model_reset")) begin
          void'(py_call_method_i64(h, "reset", none));
          if (py_last_error() != "") begin n_err++; $display("LOG model_error reset"); end   // never ignore it
        end
      end
      in_valid = 1; in_x = 16'($urandom);
      @(negedge clk);
      in_valid = 0;
      if (out_y !== fir8_step(h, in_x)) n_err++;
    end
    py_free(h);
    $display("LOG ex_lpf samples=600 errors=%0d", n_err);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
