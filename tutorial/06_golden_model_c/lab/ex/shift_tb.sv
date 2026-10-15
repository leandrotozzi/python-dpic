// Ex. 12.1-12.4: the C models checked against SV's own shift operators (the reference here).
import "DPI-C" pure function int unsigned shift_c(input int unsigned i, input int n);
import "DPI-C" function int unsigned shift_reg(input int unsigned i, input int n, input bit ld);
import "DPI-C" function chandle shift_new(input int unsigned init);
import "DPI-C" function int unsigned shift_inst(input chandle h, input int unsigned i, input int n, input bit ld);
module top;
  function automatic int unsigned sv_sh(int unsigned i, int n);
    return n > 0 ? i << n : n < 0 ? i >> -n : i;        // SV: shifting by >= 32 gives 0
  endfunction
  initial begin
    int errs = 0, nchk = 0;
    int unsigned r, exp;
    chandle a, b;
    int ns[] = '{0, 1, 4, 31, 32, 40, -1, -4, -31, -32, -40};
    foreach (ns[k]) begin
      nchk++;
      if (shift_c(32'h8000_00F1, ns[k]) !== sv_sh(32'h8000_00F1, ns[k])) begin
        errs++; $display("LOG ex12_1 n=%0d c=%h sv=%h", ns[k], shift_c(32'h8000_00F1, ns[k]), sv_sh(32'h8000_00F1, ns[k]));
      end
    end
    // Ex. 12.2: load 0x0F shifted by 4, then keep shifting the register
    exp = sv_sh(32'h0F, 4);           r = shift_reg(32'h0F, 4, 1);  errs += (r !== exp); nchk++;
    exp = sv_sh(exp, -2);             r = shift_reg(32'hFFFF, -2, 0); errs += (r !== exp); nchk++;
    $display("LOG ex12_2 reg=%h", r);
    // Ex. 12.3/12.4: two independent instances, two calls each
    a = shift_new(32'h1); b = shift_new(32'h100);
    void'(shift_inst(a, 0, 1, 0)); void'(shift_inst(b, 0, -4, 0));
    r = shift_inst(a, 0, 1, 0);       errs += (r !== 32'h4);  nchk++;
    r = shift_inst(b, 0, -4, 0);      errs += (r !== 32'h1);  nchk++;
    $display("LOG ex12_shift checks=%0d errors=%0d", nchk, errs);
    if (errs == 0) $display("PASS shift"); else $display("FAIL shift");
    $finish;
  end
endmodule
