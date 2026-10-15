// Step 01: what may a simulator do with a `pure` import? ping() secretly counts its calls.
module top;
  import "DPI-C" pure function int ping(input int x);     // lies: it has a side effect
  import "DPI-C" function int ping_raw(input int x);      // same C code, honest declaration
  import "DPI-C" function int calls();
  int y, n0;
  initial begin
    void'(ping(1));                         n0 = calls(); $display("LOG pure case=unused     calls=%0d", n0);
    y = ping(2) + ping(2);                  $display("LOG pure case=twice      calls=%0d", calls() - n0); n0 = calls();
    for (int k = 0; k < 4; k++) y += ping(3); $display("LOG pure case=loop4      calls=%0d", calls() - n0); n0 = calls();
    y = ping_raw(2) + ping_raw(2);          $display("LOG pure case=raw_twice  calls=%0d", calls() - n0);
    $finish;
  end
endmodule
