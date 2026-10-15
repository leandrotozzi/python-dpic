/* Experiment "vec": C side of packed vectors. */
#include <stdio.h>
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif

/* Print every 32-bit word, word 0 first. The last word's unused bits are shown as they arrive. */
void c_dump(const char* tag, const svBitVecVal* v, int width) {
  printf("LOG dump tag=%s n=%d", tag, SV_PACKED_DATA_NELEMS(width));
  for (int k = 0; k < SV_PACKED_DATA_NELEMS(width); k++) printf(" w%d=%08x", k, v[k]);
  printf("\n");
}
void c_dump40(const svBitVecVal* v) { printf("LOG v40 w0=%08x w1=%08x\n", v[0], v[1]); }
void c_dump_s40(const svBitVecVal* v) { printf("LOG s40 w0=%08x w1=%08x\n", v[0], v[1]); }

void c_dirty40(svBitVecVal* v) { v[0] = 0xFFFFFFFF; v[1] = 0xFFFFFFFF; /* only 8 bits of v[1] are legal */ }

/* 200-bit add: 7 words, ripple the carry. The last word has 8 valid bits: mask it. */
void c_add200(const svBitVecVal* a, const svBitVecVal* b, svBitVecVal* sum) {
  unsigned long long c = 0;
  for (int k = 0; k < 7; k++) { c += (unsigned long long)a[k] + b[k]; sum[k] = (svBitVecVal)c; c >>= 32; }
  sum[6] &= SV_MASK(200 - 6 * 32);
}

/* svGetPartselBit: read 16 bits starting at bit 100. svPutPartselBit: write 16 bits at bit 70 of w. */
void c_partsel(const svBitVecVal* v, svBitVecVal* f, svBitVecVal* w) {
  svGetPartselBit(f, v, 100, 16);
  printf("LOG partsel_in w0=%08x w2=%08x w6=%08x\n", w[0], w[2], w[6]);
  svPutPartselBit(w, 0xBEEF, 70, 16);
}

/* SV_GET_SIGNED_BITS from svdpi.h tests bit N (an unused bit), not N-1: compare with a correct version. */
int c_sign8(const svBitVecVal* v) {
  int macro = (int)SV_GET_SIGNED_BITS(*v, 8);
  int right = (int)((*v & 0x80) ? (*v | ~SV_MASK(8)) : (*v & SV_MASK(8)));
  printf("LOG sign8_c raw=%08x macro=%d right=%d\n", *v, macro, right);
  return right;
}

void c_ldump(const svLogicVecVal* v) {
  printf("LOG ldump w0.aval=%08x w0.bval=%08x w1.aval=%08x w1.bval=%08x\n", v[0].aval, v[0].bval, v[1].aval, v[1].bval);
}
/* Table 12.2 encoding, bit by bit: 0=(a0,b0) 1=(a1,b0) Z=(a0,b1) X=(a1,b1). Writes 8'b01zx_01zx. */
void c_lwrite(svLogicVecVal* v) { v->aval = 0x55; v->bval = 0x33; }
#ifdef __cplusplus
}
#endif
