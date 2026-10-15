/* Golden (reference) models for tutorial/common/rtl: crc32_stream and fir8.
 * Implements the imports declared in golden_pkg.sv. Verilator compiles .c files with the C++
 * compiler, so the definitions need C linkage (extern "C") to match the names SV calls.
 *
 * Bug injection for the lab (compile-time, so the checker can be proven to fire):
 *   -DMUTANT=1  FIR rounds by truncation (drops the +2^14)
 *   -DMUTANT=2  FIR wraps instead of saturating
 *   -DMUTANT=3  CRC table has one wrong entry (hit on ~1 of every 256 bytes)
 *   -DMUTANT=4  FIR accumulates in 32 bits (the true sum needs 35): wraps on large sums
 */
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"   /* Verilator-generated prototypes: a signature mismatch fails to compile */
#ifndef MUTANT
#define MUTANT 0
#endif
#ifdef __cplusplus
extern "C" {
#endif

/* ------------------------------------------------------------------ CRC-32 */
/* Two independent implementations: bitwise (same algorithm as the RTL) and table-driven
 * (a different algorithm). The golden model uses the table: a model that transliterates the
 * RTL tends to share its bugs. The bitwise one only builds and self-checks the table. */
static uint32_t crc_tab[256];

static uint32_t crc32_bitwise_byte(uint32_t s, uint8_t b) {
  s ^= b;
  for (int k = 0; k < 8; k++) s = (s & 1) ? (s >> 1) ^ 0xEDB88320u : (s >> 1);
  return s;
}
static void crc_tab_init(void) {
  if (crc_tab[1]) return;                       /* already built */
  for (int i = 0; i < 256; i++) crc_tab[i] = crc32_bitwise_byte(0, (uint8_t)i);
  if (MUTANT == 3) crc_tab[0x5A] ^= 0x00010000u;
}
static inline uint32_t crc_step(uint32_t s, uint8_t b) { return (s >> 8) ^ crc_tab[(s ^ b) & 0xFF]; }

typedef struct { uint32_t state; } crc_t;       /* register value, before the final inversion */

void* crc32_new(void) { crc_tab_init(); crc_t* c = (crc_t*)malloc(sizeof *c); c->state = 0xFFFFFFFFu; return c; }
void  crc32_free(void* h) { free(h); }
void  crc32_clear(void* h) { ((crc_t*)h)->state = 0xFFFFFFFFu; }
unsigned int crc32_update(void* h, unsigned char b) {
  crc_t* c = (crc_t*)h;
  c->state = crc_step(c->state, b);
  return ~c->state;                             /* same as the DUT's crc output after this byte */
}
unsigned int crc32_msg(const svOpenArrayHandle msg, int len) {
  crc_tab_init();
  if (len < 0 || len > svSize(msg, 1)) {         /* a contract violation, not a mismatch */
    fprintf(stderr, "crc32_msg: len=%d outside buffer of %d\n", len, svSize(msg, 1));
    abort();
  }
  uint32_t s = 0xFFFFFFFFu;
  const uint8_t* p = (const uint8_t*)svGetArrayPtr(msg);   /* NULL if not C-contiguous (LRM H.12) */
  if (!p) { fprintf(stderr, "crc32_msg: array not contiguous\n"); abort(); }
  for (int i = 0; i < len; i++) s = crc_step(s, p[i]);
  return ~s;
}

/* ------------------------------------------------------------------- FIR8 */
typedef struct { int16_t coef[8]; int16_t dly[8]; } fir_t;   /* dly[0] = x[n-1] */

static int16_t fir_q15(const fir_t* f, int16_t x) {
  int64_t acc = (int64_t)f->coef[0] * x;                     /* 35 bits fit easily in 64 */
  for (int k = 1; k < 8; k++) acc += (int64_t)f->coef[k] * f->dly[k - 1];
  if (MUTANT == 4) acc = (int32_t)(uint32_t)acc;              /* what an `int acc` would hold */
  int64_t r = (MUTANT == 1 ? acc : acc + (1 << 14)) >> 15;   /* arithmetic shift = floor */
  if (MUTANT == 2) return (int16_t)r;                         /* wraps */
  return (int16_t)(r > 32767 ? 32767 : r < -32768 ? -32768 : r);
}
static void fir_push(fir_t* f, int16_t x) {
  for (int k = 7; k > 0; k--) f->dly[k] = f->dly[k - 1];
  f->dly[0] = x;
}

void* fir8_new(const short* coef) {
  fir_t* f = (fir_t*)calloc(1, sizeof *f);
  for (int k = 0; k < 8; k++) f->coef[k] = coef[k];
  return f;
}
void  fir8_free(void* h) { free(h); }
short fir8_step(void* h, short x) {
  fir_t* f = (fir_t*)h;
  int16_t y = fir_q15(f, x);
  fir_push(f, x);
  return y;
}
void fir8_block(void* h, const svOpenArrayHandle x, const svOpenArrayHandle y, int n) {
  if (n < 0 || n > svSize(x, 1) || n > svSize(y, 1)) {
    fprintf(stderr, "fir8_block: n=%d but size(x)=%d size(y)=%d\n", n, svSize(x, 1), svSize(y, 1));
    abort();
  }
  const short* xp = (const short*)svGetArrayPtr(x);
  short*       yp = (short*)svGetArrayPtr(y);
  if (!xp || !yp) { fprintf(stderr, "fir8_block: array not contiguous\n"); abort(); }
  for (int i = 0; i < n; i++) yp[i] = fir8_step(h, xp[i]);
}
#ifdef __cplusplus
}
#endif
