// chandle rule 4 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  chandle g; assign g = h;         // LRM: illegal (continuous assignment)
endmodule
