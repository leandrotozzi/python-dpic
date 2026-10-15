// T10 test: three instances accumulate independently, keyed by %m.
import "DPI-C" function int acc_by_name(input string who, input int x);
import "DPI-C" function int acc_instances();

module accum #(parameter int STEP = 1) (input bit clk);
  string me = $sformatf("%m");              // computed once, not per call
  int    sum;
  always @(posedge clk) sum <= acc_by_name(me, STEP);
endmodule

module top;
  bit clk;
  accum #(1) a (clk);  accum #(10) b (clk);  accum #(100) c (clk);
  initial begin
    repeat (5) begin #5 clk = 1; #5 clk = 0; end
    $display("LOG registry a=%0d b=%0d c=%0d n=%0d name_b=%s", a.sum, b.sum, c.sum, acc_instances(), b.me);
    $finish;
  end
endmodule
