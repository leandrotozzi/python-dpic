// chandle rule 5 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  always @(h) $display("chg");    // LRM: illegal (event expression)
endmodule
