`timescale 1ns/1ns
// Exercise: C calls the export of EVERY instance of a generate array, by name,
// and each instance keeps a private C counter hung on its scope (svPutUserData).
module unit #(parameter int ID = 0);
  import "DPI-C" context function void hello();
  export "DPI-C" function sv_ping;
  function int sv_ping(int k); return ID * 100 + k; endfunction
  initial hello();
endmodule
module top;
  import "DPI-C" context function int broadcast(int n);
  for (genvar g = 0; g < 3; g++) begin : gen
    unit #(.ID(g)) u();
  end
  initial #1 begin
    $display("LOG bcast sum=%0d", broadcast(3));
    $finish;
  end
endmodule
