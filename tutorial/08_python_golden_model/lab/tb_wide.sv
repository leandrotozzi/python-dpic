`timescale 1ns/1ps
// py_mul_wide (100 x 100 -> 200 bits, Python int) checked against SV's own wide multiply.
module top;
  import py_extra_pkg::*;
  bit [99:0]  a, b;
  bit [199:0] p, ref_p;
  int n_err;
  string e;
  initial begin
    for (int n = 0; n < 1000; n++) begin
      case (n)
        0: begin a = '1; b = '1; end                               // largest product: 2^200 - 2^101 + 1
        1: begin a = 100'd1 << 99; b = 100'd2; end                 // carry into bit 100
        2: begin a = 0; b = '1; end
        default: begin a = {$urandom, $urandom, $urandom, 4'($urandom)}; b = {$urandom, $urandom, $urandom, 4'($urandom)}; end
      endcase
      py_mul_wide(a, b, p);
      ref_p = 200'(a) * 200'(b);
      e = py_last_error();
      if (e != "" || p !== ref_p) begin
        n_err++;
        if (n_err <= 3) $display("MISMATCH a=%h b=%h p=%h ref=%h err='%s'", a, b, p, ref_p, e);
      end
      if (n == 0) $display("LOG wide max_product=%h", p);
    end
    $display("LOG wide n=1000 errors=%0d", n_err);
    if (n_err == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
