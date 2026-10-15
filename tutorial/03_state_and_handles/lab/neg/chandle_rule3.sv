// chandle rule 3 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  initial if (h) $display("set"); // LRM: legal (chandle as boolean)
endmodule
