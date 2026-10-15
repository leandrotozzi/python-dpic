// IEEE 1800-2023 35.5.1.6: a C++ exception must not cross the DPI boundary (undefined behavior).
// +throw makes the C++ model throw; the lab records what happens to the simulation.
module top;
  import "DPI-C" function int model_step(input int x, input bit fail);
  initial begin
    $display("LOG exc before r=%0d", model_step(1, 0));
    $display("LOG exc after r=%0d", model_step(2, $test$plusargs("throw")));
    $finish;
  end
  final $display("LOG exc final");
endmodule
