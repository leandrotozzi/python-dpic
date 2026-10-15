// Step 01: first DPI-C imports. C side in hello.c (or hdr.c, which includes the generated header).
// Samples 12.1-12.6 of Spear & Tumbush, ported to a module and to Verilator.
module top;
  // Sample 12.1/12.5: C int <-> SV int (2-state, signed, 32 bits on both sides)
  import "DPI-C" pure function int factorial(input int i);
  // Sample 12.6: libm functions need no wrapper at all; SV real == C double
  import "DPI-C" pure function real fabs(input real x);
  import "DPI-C" pure function real sin(input real x);
  import "DPI-C" pure function real pow(input real x, input real y);
  // Sample 12.3: c_name = sv_name. "expect" is an SV keyword, so the SV side gets another name.
  import "DPI-C" \expect = function int fexpect();  // escaped: the lexer sees a keyword otherwise
  // Rename a libc routine: access(2) from <unistd.h> (F_OK = 0) checks if a file exists
  import "DPI-C" access = function int file_access(input string path, input int mode);
  // Sample 12.4: output arguments arrive in C as pointers
  import "DPI-C" function int addmul(input int a, input int b, output int sum);

  initial begin
    int s, p;
    for (int i = -1; i <= 13; i++) $display("LOG fact i=%0d f=%0d", i, factorial(i));
    $display("LOG libm fabs=%0.3f sin30=%0.6f pow=%0.1f", fabs(-1.5), sin(3.14159265358979 / 6), pow(2.0, 10.0));
    $display("LOG rename fexpect=%0d", fexpect());
    $display("LOG access sv=%0d none=%0d", file_access("hello.sv", 0), file_access("none.such", 0));
    p = addmul(6, 7, s);
    $display("LOG addmul p=%0d s=%0d", p, s);
    $finish;
  end
endmodule
