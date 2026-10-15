`timescale 1ns/1ns
// What happens when an import WITHOUT `context` calls an export?
//  default : first DPI call of the simulation -> no scope at all
//  STALE   : a context import in `other` ran before -> the export resolves in the WRONG scope
module other;
  import "DPI-C" context function void touch();
  export "DPI-C" function sv_hello;
  function void sv_hello();
    $display("LOG sv hello where=%m");
  endfunction
`ifdef STALE
  initial touch();
`endif
endmodule

module top;
  import "DPI-C" function void call_export();             // NOT context
  export "DPI-C" function sv_hello;
  function void sv_hello();
    $display("LOG sv hello where=%m");
  endfunction
  other o();
  initial begin
    #1 call_export();
    $display("LOG sv after");
    $finish;
  end
endmodule
