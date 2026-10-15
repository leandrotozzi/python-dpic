// Exercises 2-3 (Spear Ex. 12.1 and 12.2): shift_c, then shift_ld_c with an internal register.
import "DPI-C" function int unsigned shift_c(input int unsigned i, input int n);
import "DPI-C" function int unsigned shift_naive_c(input int unsigned i, input int n);
import "DPI-C" function int unsigned shift_ld_c(input int unsigned i, input int n, input bit ld);
module top;
  function automatic int unsigned shift_sv(int unsigned i, int n);   // the reference: SV shift semantics
    return n >= 0 ? i << n : i >> -n;
  endfunction
  int ns[] = '{0, 1, 4, 31, 32, 40, -1, -4, -31, -32, -40};
  int unsigned i = 32'h8000_00F1, r, ref_reg;
  int errs = 0;
  initial begin
    foreach (ns[k]) begin
      r = shift_c(i, ns[k]);
      $display("LOG shift n=%0d r=%h", ns[k], r);
      if (r != shift_sv(i, ns[k])) errs++;
    end
    // Ex. 12.2: ld=1 loads (i shifted), ld=0 shifts the register
    r = shift_ld_c(32'h0000_00FF, 4, 1);  ref_reg = 32'h0000_0FF0;  if (r != ref_reg) errs++;
    r = shift_ld_c(32'hDEAD_BEEF, -8, 0); ref_reg = ref_reg >> 8;   if (r != ref_reg) errs++;
    r = shift_ld_c(0, 40, 0);             ref_reg = 0;              if (r != ref_reg) errs++;
    $display("LOG shift_ld last=%h", r);
    $display("LOG shift_naive n32=%h n40=%h", shift_naive_c(i, 32), shift_naive_c(i, 40));
    $display("LOG ex_shift errs=%0d", errs);
    if (errs == 0) $display("PASS"); else $display("FAIL");
    $finish;
  end
endmodule
