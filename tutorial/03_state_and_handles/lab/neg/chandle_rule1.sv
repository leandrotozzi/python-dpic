// chandle rule 1 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  int x; initial x = h;            // LRM: illegal (chandle -> other type)
endmodule
