/* Exercise 7. An output starts with undetermined contents: clear every word, then put the field. */
#include <string.h>
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
void c_scratch200(const svBitVecVal* v) { (void)v; }
void c_put16(svBitVecVal* w, const svBitVecVal* f, int lsb) {
  memset(w, 0, SV_PACKED_DATA_NELEMS(200) * sizeof(svBitVecVal));
  svPutPartselBit(w, *f, lsb, 16);
}
#ifdef __cplusplus
}
#endif
