// Two independent, heavy blocks so Verilator's scheduler can put them on different threads.
import "DPI-C" pure function int tag_pure(input int x);
import "DPI-C"      function int tag_impure(input int x);
import "DPI-C"      function int n_pure_threads();
import "DPI-C"      function int n_impure_threads();

module work #(parameter bit PURE = 1) (input bit clk, input int seed, output int acc);
  int a [64];
  always_ff @(posedge clk)
    for (int k = 0; k < 64; k++)
      a[k] <= a[(k + 1) % 64] ^ (PURE ? tag_pure(seed + k) : tag_impure(seed + k)) ^ (a[k] * 7);
  always_comb begin acc = 0; foreach (a[k]) acc ^= a[k]; end
endmodule

module top;
  bit clk;
  int s0, s1, s2, s3, acc0, acc1, acc2, acc3;
  work #(1) p0 (clk, s0, acc0);  work #(1) p1 (clk, s1, acc1);
  work #(0) q0 (clk, s2, acc2);  work #(0) q1 (clk, s3, acc3);
  initial begin
    for (int c = 0; c < 2000; c++) begin
      s0 = c; s1 = c + 1000; s2 = c + 2000; s3 = c + 3000;
      #5 clk = 1; #5 clk = 0;
    end
    $display("LOG threads pure=%0d impure=%0d acc=%0d", n_pure_threads(), n_impure_threads(), acc0 ^ acc1 ^ acc2 ^ acc3);
    $finish;
  end
endmodule
