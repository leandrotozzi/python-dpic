// Ex. 12.3-12.6 in Python: each SV-side instance owns a Python object through a chandle.
import "DPI-C" function int          sh_init();
import "DPI-C" function chandle      sh_new(input int unsigned init);
import "DPI-C" function int unsigned sh_step(input chandle h, input int unsigned i, input int n, input bit ld);
import "DPI-C" function int          sh_calls();
import "DPI-C" function void         sh_free(input chandle h);
import "DPI-C" function int          sh_live();
import "DPI-C" function void         sh_fin();
module top;
  chandle a, b;
  initial begin
    void'(sh_init());
    a = sh_new(32'h1);
    b = sh_new(32'hF000_0000);
    $display("LOG sh a1=%h b1=%h", sh_step(a, 0, 4, 0), sh_step(b, 0, -4, 0));
    $display("LOG sh a2=%h b2=%h", sh_step(a, 32'h3, 1, 1), sh_step(b, 0, -4, 0));
    $display("LOG sh calls=%0d live=%0d", sh_calls(), sh_live());
    sh_free(a); sh_free(b);
    $display("LOG sh live_after_free=%0d", sh_live());
    $finish;
  end
  final sh_fin();
endmodule
