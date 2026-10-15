// chandle rule 2 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  chandle g; initial g = h + 1;    // LRM: illegal (no chandle arithmetic)
endmodule
