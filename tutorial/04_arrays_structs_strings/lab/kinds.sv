// Can a dynamic array or a queue be the actual of an open-array formal?
// IEEE 1800-2023 35.5.6.1 says yes (any unpacked array). Built with -DDYN / -DQUE / -DSLICE.
import "DPI-C" function int sum_oa(input int a[]);
module top;
  int fixed4[4] = '{1, 2, 3, 4};
`ifdef DYN
  int dyn[] = '{1, 2, 3, 4};
`elsif QUE
  int dyn[$] = '{1, 2, 3, 4};
`else
  int dyn[4] = '{1, 2, 3, 4};
`endif
  initial begin
`ifdef SLICE
    $display("LOG kinds slice=%0d", sum_oa(fixed4[1:2]));
`endif
    $display("LOG kinds sum=%0d", sum_oa(dyn));
    $finish;
  end
endmodule
