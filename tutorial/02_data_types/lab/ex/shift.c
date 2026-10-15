/* Exercises 2-3 (Spear Ex. 12.1 / 12.2). Pitfall: in C, shifting a 32-bit value by >= 32 is undefined
   behavior (x86 masks the count to 5 bits, so x << 32 == x). SV defines it as 0. Handle it explicitly. */
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
unsigned int shift_c(unsigned int i, int n) {
  if (n >= 32 || n <= -32) return 0;
  return n >= 0 ? i << n : i >> -n;
}
unsigned int shift_naive_c(unsigned int i, int n) { return n >= 0 ? i << n : i >> -n; }  /* UB for |n| >= 32 */
unsigned int shift_ld_c(unsigned int i, int n, svBit ld) {
  static unsigned int reg;               /* ONE register for the whole simulation: step 03 fixes that */
  reg = shift_c(ld ? i : reg, n);
  return reg;
}
#ifdef __cplusplus
}
#endif
