// Samples 12.34 + 12.46: one C routine, two SV scopes. Each scope imports the same
// context function and exports its own sv_display; C ends up in the caller's scope.
module block;
  import "DPI-C" context function void c_display();
  export "DPI-C" function sv_display;            // no return type, no args, no ()
  function void sv_display();
    $display("LOG sv where=%m");
  endfunction
  initial c_display();
endmodule

module top;
  import "DPI-C" context function void c_display();
  export "DPI-C" function sv_display;
  function void sv_display();
    $display("LOG sv where=%m");
  endfunction
  block b1();
  initial #1 c_display();
  initial #2 $finish;
endmodule
