// Ex. 12.3 + 12.4 + 12.5: per-instance shifter. Each instance is a heap object; its address
// is its identity. A static counts calls across ALL instances (Ex. 12.4); shift_new(init)
// sets the initial register value (Ex. 12.5).
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef struct { uint32_t reg; int calls; } shifter;
static int total_calls = 0;                      // shared by every instance on purpose

static uint32_t shift(uint32_t v, int n) {
  if (n >= 32 || n <= -32) return 0;
  return n >= 0 ? v << n : v >> -n;
}
extern "C" {
void* shift_new(uint32_t init) { shifter* s = (shifter*)calloc(1, sizeof *s); s->reg = init; return s; }
void  shift_free(void* h) { free(h); }
int   shift_total(void) { return total_calls; }
int   shift_calls(void* h) { return ((shifter*)h)->calls; }
uint32_t shift_c(void* h, uint32_t i, int n, unsigned char ld) {
  shifter* s = (shifter*)h;
  s->reg = shift(ld ? i : s->reg, n);
  s->calls++; total_calls++;
  printf("LOG ex3 addr=%p i=%08x n=%d ld=%d reg=%08x\n", h, i, n, ld, s->reg);
  return s->reg;
}
}
