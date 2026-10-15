/* Ex. 12.1: unsigned so >> is logical; |n| >= 32 clamped because x << 32 is undefined in C. */
#include "Vtop__Dpi.h"
unsigned int shift_c(unsigned int i, int n) {
  if (n >= 32 || n <= -32) return 0;
  return n > 0 ? i << n : n < 0 ? i >> -n : i;
}
