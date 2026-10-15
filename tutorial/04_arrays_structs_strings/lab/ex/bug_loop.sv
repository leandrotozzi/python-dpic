// Exercise 4 (find the bug): C assumes 0-based arrays.
import "DPI-C" function int sum_bug(input int a[]);
module top;
  int a[10:1];
  initial begin
    foreach (a[i]) a[i] = i;
    $display("LOG bug_loop sum=%0d", sum_bug(a));
    $finish;
  end
endmodule
