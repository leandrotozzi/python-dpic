/* Exercise 10. Portable 32-bit limbs (no __int128): p = a*b as four svBitVecVal words. */
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
void c_mul128(unsigned long long a, unsigned long long b, svBitVecVal* p) {
  unsigned int x[2] = {(unsigned int)a, (unsigned int)(a >> 32)};
  unsigned int y[2] = {(unsigned int)b, (unsigned int)(b >> 32)};
  unsigned long long acc[4] = {0, 0, 0, 0};
  for (int i = 0; i < 2; i++) {
    unsigned long long carry = 0;
    for (int j = 0; j < 2; j++) {
      unsigned long long t = (unsigned long long)x[i] * y[j] + acc[i + j] + carry;
      acc[i + j] = t & 0xFFFFFFFFu;
      carry = t >> 32;
    }
    acc[i + 2] += carry;
  }
  for (int k = 0; k < 4; k++) p[k] = (svBitVecVal)acc[k];
}
#ifdef __cplusplus
}
#endif
