// Ex. 12.2: shift_c(i, n, ld). ld=1: reg = i shifted by n. ld=0: reg shifted by n.
// n > 0 shifts left, n < 0 right, |n| >= 32 clears (a C shift by >= width is undefined behavior).
#include <stdint.h>
static uint32_t shift(uint32_t v, int n) {
  if (n >= 32 || n <= -32) return 0;
  return n >= 0 ? v << n : v >> -n;
}
extern "C" uint32_t shift_c(uint32_t i, int n, unsigned char ld) {
  static uint32_t reg = 0;                       // the single, shared internal register
  reg = shift(ld ? i : reg, n);
  return reg;
}
