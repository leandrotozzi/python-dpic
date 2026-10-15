/* Exercise 5. The LRM leaves the unused bits of the last word undetermined: mask them before counting. */
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
int c_popcount200(const svBitVecVal* v) {
  const int W = 200, N = SV_PACKED_DATA_NELEMS(W);
  int n = 0;
  for (int k = 0; k < N; k++) {
    svBitVecVal w = (k == N - 1 && W % 32) ? v[k] & SV_MASK(W % 32) : v[k];
    n += __builtin_popcount(w);
  }
  return n;
}
#ifdef __cplusplus
}
#endif
