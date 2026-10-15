`timescale 1ns/1ns
// An output argument C never writes: does SV keep its old value?
module top;
  import "DPI-C" function void skip_out(input int k, output int o);
  int o1 = 7, o2 = 7;
  initial begin
    skip_out(1, o1);                       // C writes nothing
    skip_out(2, o2);
    $display("LOG outarg before=7 after1=%0d after2=%0d", o1, o2);
    $finish;
  end
endmodule
