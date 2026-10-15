`timescale 1ns/1ns
// Exercise "predict the output": three scopes, one C routine.
module leaf;
  import "DPI-C" context function void hop();
  export "DPI-C" function who;
  function void who(); $display("LOG who %m"); endfunction
  initial #2 hop();
endmodule
module mid;
  export "DPI-C" function who;
  function void who(); $display("LOG who %m"); endfunction
  leaf l();
endmodule
module top;
  import "DPI-C" context function void hop();
  import "DPI-C" context function void pin();
  export "DPI-C" function who;
  function void who(); $display("LOG who %m"); endfunction
  mid m();
  initial begin
    #1 hop();
    #2 pin();
    #1 hop();
    #1 $finish;
  end
endmodule
