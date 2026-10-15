/* Experiment "dir": what C sees through output/inout pointers, and what SV gets back. */
#include <stdio.h>
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif

/* LRM: the initial value of an output formal is undetermined. Never read it. */
void c_peek_out(int* o) { printf("LOG c_peek in=%d\n", *o); *o = 1; }

void c_scratch(const svBitVecVal* v) { (void)v; }

/* An output the C code does not write: SV still copies the temporary back. */
void c_skip_out(int* o, svBitVecVal* v) { printf("LOG c_skip o_in=%d v_in=%02x%08x\n", *o, v[1], v[0]); }

/* inout: C sees the current SV value and may update it. */
void c_inc_inout(int* io, svBitVecVal* v) {
  *io += 1;
  unsigned long long x = ((unsigned long long)v[1] << 32 | v[0]) + 1;
  v[0] = (svBitVecVal)x; v[1] = (svBitVecVal)(x >> 32) & SV_MASK(8);
}

/* input i and output o are the same SV variable: are they the same storage in C? */
void c_alias(int i, int* o) { *o = 100; printf("LOG c_alias i_after_write=%d\n", i); }

void c_bad_bit(svBit* b, svLogic* l) { *b = 0xFE; *l = 0xFE; }
#ifdef __cplusplus
}
#endif
