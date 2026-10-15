// C side of structs.sv. A packed struct is just a packed vector: svBitVecVal words, LSB first.
#include <stdio.h>
#include "svdpi.h"
extern "C" {

// Sample 12.28: overlay a C struct on the vector. Works only on a little-endian host,
// and only because the 24 bits sit in the low 3 bytes of the first 32-bit word.
typedef struct { unsigned char b, g, r; } *p_rgb;
void invert(svBitVecVal* v) {
  p_rgb rgb = (p_rgb)v;
  rgb->r = ~rgb->r; rgb->g = ~rgb->g; rgb->b = ~rgb->b;
}

// Portable: field = (word >> lsb) & mask, independent of host endianness.
void invert_bits(svBitVecVal* v) { *v = ~*v & 0x00FFFFFFu; }

// 112-bit struct -> 4 words. etype is bits [15:0], src [63:16], dst [111:64].
int etype_of(const svBitVecVal* h) {
  svBitVecVal e;
  svGetPartselBit(&e, h, 0, 16);
  return e;
}

void make_hdr(svBitVecVal* h) {
  svBitVecVal dst_lo = 0x55667788u, dst_hi = 0x1122u, src_lo = 0xA0A0A0A0u, src_hi = 0xB0B0u, et = 0x86DD;
  svPutPartselBit(h, et, 0, 16);
  svPutPartselBit(h, src_lo, 16, 32);
  svPutPartselBit(h, src_hi, 48, 16);
  svPutPartselBit(h, dst_lo, 64, 32);
  svPutPartselBit(h, dst_hi, 96, 16);
}

#ifdef UNPACKED_C
typedef struct { int a; char b; short c; } ups_t;
int ups_sum(const ups_t* s) { return s->a + s->b + s->c; }
#endif
}
