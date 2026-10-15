// IEEE 1800-2023 35.5.2 / 35.5.1.3: only nonvoid functions without output/inout can be pure,
// and an imported task can never be pure (the grammar only allows `context` on tasks).
// Each variant is illegal; the lab records whether Verilator 5.052 says anything.
module top;
`ifdef VOID
  import "DPI-C" pure function void pr_void(input int a);
  initial begin pr_void(1); $display("LOG prule case=void built=1"); $finish; end
`elsif TASK
  import "DPI-C" pure task pr_task(input int a);
  initial begin pr_task(1); $display("LOG prule case=task built=1"); $finish; end
`else
  import "DPI-C" pure function int pr_out(input int a, output int b);
  int b;
  initial begin $display("LOG prule case=out r=%0d b=%0d", pr_out(3, b), b); $finish; end
`endif
endmodule
