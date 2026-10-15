// Ex. 2: longint factorial. 20! fits in 64 bits, 21! does not.
module top;
  import "DPI-C" pure function longint factorial64(input int i);
  initial begin
    $display("LOG fact64 f13=%0d f20=%0d f21=%0d", factorial64(13), factorial64(20), factorial64(21));
    $finish;
  end
endmodule
