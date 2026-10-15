// Ex: lazy initialization. No init call from SV; the module path comes from $PY_DPI_PATH.
import "DPI-C" function int  lazy_add(input int a, input int b);
import "DPI-C" function int  lazy_inits();
import "DPI-C" function void lazy_fin();
module top;
  initial begin
    $display("LOG lazy a=%0d b=%0d inits=%0d", lazy_add(1, 2), lazy_add(3, 4), lazy_inits());
    $finish;
  end
  final lazy_fin();
endmodule
