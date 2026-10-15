// Ex. 12.3/12.4/12.5 test: two instances, each called twice; distinct addresses, separate state.
import "DPI-C" function chandle shift_new(input int unsigned init);
import "DPI-C" function void shift_free(input chandle h);
import "DPI-C" function int  shift_total();
import "DPI-C" function int  shift_calls(input chandle h);
import "DPI-C" function int unsigned shift_c(input chandle h, input int unsigned i, input int n, input bit ld);
module top;
  chandle a, b;
  initial begin
    a = shift_new(32'h1);                  // Ex. 12.5: initial value at instantiation
    b = shift_new(32'h8000_0000);
    void'(shift_c(a, 0, 4, 0));            // 1 << 4      = 10
    void'(shift_c(b, 0, -4, 0));           // 8000_0000>>4 = 0800_0000
    $display("LOG ex345 a=%h b=%h", shift_c(a, 0, 1, 0), shift_c(b, 0, -1, 0));
    $display("LOG ex345 calls_a=%0d calls_b=%0d total=%0d", shift_calls(a), shift_calls(b), shift_total());
    shift_free(a); shift_free(b);
    $finish;
  end
endmodule
