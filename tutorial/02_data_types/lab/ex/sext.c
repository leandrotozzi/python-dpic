/* Exercise 6. Word 1 carries bits [39:32] only; nobody sign-extends bits [63:40] for you. */
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
long long c_s40_bad(const svBitVecVal* v) { return (long long)((unsigned long long)v[1] << 32 | v[0]); }
long long c_s40(const svBitVecVal* v) {
  unsigned long long u = ((unsigned long long)(v[1] & SV_MASK(8)) << 32) | v[0];
  return (long long)(u << 24) >> 24;      /* move bit 39 to bit 63, arithmetic shift back */
}
#ifdef __cplusplus
}
#endif
