// Ex. 5 fix: no SV type produces C `size_t` (unsigned long), so wrap strlen in one line of C.
module top;
  import "DPI-C" pure function longint c_strlen(input string s);
  initial begin
    string s = "hello";
    $display("LOG strlen empty=%0d hello=%0d len=%0d", c_strlen(""), c_strlen(s), s.len());
    $finish;
  end
endmodule
