// Step 07, experiment "basic": explicit init, cached callables, type conversion, finalize in `final`.
import "DPI-C" function int     py_init(input string moddir);
import "DPI-C" function void    py_fin();
import "DPI-C" function int     py_add(input int a, input int b);
import "DPI-C" function int     py_add_checked(input int a, input int b, output int sum);
import "DPI-C" function real    py_hypot(input real x, input real y);
import "DPI-C" function string  py_reverse(input string s);
import "DPI-C" function int     py_checksum(input byte unsigned d[]);
import "DPI-C" function longint py_pow2(input int n);
import "DPI-C" function string  py_whoami();

module top;
  string dir = "py";
  byte unsigned msg[4];               // fixed size: this simulator rejects a dynamic array here
  int s, rc;
  initial begin
    void'($value$plusargs("pydir=%s", dir));
    if (py_init(dir) != 0) $fatal(1, "python init failed");
    $display("LOG who %s", py_whoami());
    $display("LOG add r=%0d", py_add(2, 40));
    $display("LOG wrap r=%0d", py_add(32'h7fff_ffff, 1));            // silently wraps
    rc = py_add_checked(32'h7fff_ffff, 1, s);
    $display("LOG checked rc=%0d", rc);
    rc = py_add_checked(-5, 3, s);
    $display("LOG checked2 rc=%0d sum=%0d", rc, s);
    $display("LOG hypot r=%0.6f", py_hypot(3.0, 4.0));
    $display("LOG reverse r=%s", py_reverse("DPI-C rocks"));
    msg = '{8'h01, 8'h02, 8'hff, 8'h10};
    $display("LOG checksum r=%0d", py_checksum(msg));
    $display("LOG pow2 p62=%0d p63=%0d p64=%0d", py_pow2(62), py_pow2(63), py_pow2(64));
    $finish;
  end
  final begin
    py_fin();
    $display("LOG final done");
  end
endmodule
