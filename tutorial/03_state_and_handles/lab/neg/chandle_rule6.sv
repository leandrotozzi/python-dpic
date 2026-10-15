// chandle rule 6 (IEEE 1800-2023 6.14). Linted, not simulated.
module top;
  chandle h;
  typedef struct packed { chandle p; } s_t;   // LRM: illegal (packed type)
endmodule
