`timescale 1ns/1ns
// Samples 12.48–12.50: save a scope from `block`, later jump back into it from `top`.
// Plus svGetScopeFromName with the names Verilator accepts, and svPutUserData per scope.
module block;
  import "DPI-C" context function void c_display();
  import "DPI-C" context function void save_my_scope();
  import "DPI-C" context function int  bump();         // per-scope counter via user data
  export "DPI-C" function sv_display;
  function void sv_display();
    $display("LOG sv where=%m");
  endfunction
  initial begin
    save_my_scope();
    c_display();
  end
  initial #3 $display("LOG bump where=%m n=%0d", bump());
endmodule

module top;
  import "DPI-C" context function void c_display();
  import "DPI-C" context function void by_name(string name);
  import "DPI-C" context function int  bump();
  export "DPI-C" function sv_display;
  function void sv_display();
    $display("LOG sv where=%m");
  endfunction
  block b1();
  block b2();
  initial begin
    #1 c_display();
    #1 by_name("top.b2"); by_name("TOP.top.b2"); by_name("b2"); by_name("top.nope");
    #2 begin
      for (int i = 0; i < 3; i++) void'(bump());
      $display("LOG bump where=%m n=%0d", bump());
    end
    #1 $finish;
  end
endmodule
