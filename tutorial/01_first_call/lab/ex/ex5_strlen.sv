// Ex. 5: import libc strlen directly. size_t is 64 bits on LP64 -> longint unsigned.
module top;
  import "DPI-C" pure strlen = function longint unsigned c_strlen(input string s);
  initial begin
    string s = "hello";
    $display("LOG strlen empty=%0d hello=%0d len=%0d", c_strlen(""), c_strlen(s), s.len());
    $finish;
  end
endmodule
