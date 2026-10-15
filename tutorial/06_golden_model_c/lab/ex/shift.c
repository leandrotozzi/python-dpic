/* Ex. 12.1-12.4 (Spear & Tumbush) recast as golden models.
 * shift_c:   stateless.  n > 0 shifts left, n < 0 shifts right (logical), n == 0 passes through.
 * shift_reg: Ex. 12.2, one static 32-bit register shared by every caller.
 * shift_new/shift_inst: Ex. 12.3/12.4, per-instance register behind a chandle + a global call counter. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "Vtop__Dpi.h"

/* C makes `x << 32` undefined behavior; SV defines it as 0. The model must say what it means. */
static uint32_t sh(uint32_t i, int n) {
  if (n >= 32 || n <= -32) return 0;
  return n > 0 ? i << n : n < 0 ? i >> -n : i;
}
unsigned int shift_c(unsigned int i, int n) { return sh(i, n); }

static uint32_t reg;                                    /* Ex. 12.2: one register for everyone */
unsigned int shift_reg(unsigned int i, int n, unsigned char ld) {
  reg = ld ? sh(i, n) : sh(reg, n);
  return reg;
}

static unsigned long calls;                             /* Ex. 12.4: counts every instance */
void* shift_new(unsigned int init) {                    /* Ex. 12.5: initial value */
  uint32_t* r = (uint32_t*)malloc(sizeof *r);
  *r = init;
  return r;
}
unsigned int shift_inst(void* h, unsigned int i, int n, unsigned char ld) {
  uint32_t* r = (uint32_t*)h;
  *r = ld ? sh(i, n) : sh(*r, n);
  calls++;
  printf("LOG shift_inst inst=%p i=%08x n=%d ld=%d reg=%08x calls=%lu\n", h, i, n, ld, *r, calls);
  fflush(stdout);
  return *r;
}
