/* Exercise 11. A bit is X or Z when its bval is 1 (Table 12.2). Mask the unused bits of the last word.
   With -DUNIT this file is also a plain C program that tests the function on hand-built X/Z values. */
#include <stdio.h>
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
int count_xz(const svLogicVecVal* v, int width) {
  int n = 0;
  for (int k = 0; k < SV_PACKED_DATA_NELEMS(width); k++) {
    unsigned int b = v[k].bval;
    if (k == SV_PACKED_DATA_NELEMS(width) - 1 && width % 32) b &= SV_MASK(width % 32);
    n += __builtin_popcount(b);
  }
  return n;
}
int c_count_xz(const svLogicVecVal* v) { return count_xz(v, 40); }
#ifdef __cplusplus
}
#endif
#ifdef UNIT
int main(void) {
  /* 40'hzz_xxxx_0001: bits [39:32] Z (a0 b1), [31:16] X (a1 b1), [15:0] = 1. Garbage in unused bits. */
  svLogicVecVal v[2] = {{0xFFFF0001u, 0xFFFF0000u}, {0xAB000000u, 0xCD0000FFu}};
  printf("LOG ex_xz unit=%d\n", count_xz(v, 40));
  return count_xz(v, 40) != 24;
}
#endif
