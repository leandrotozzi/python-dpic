// Sample 12.9 (corrected): per-instance state. counter7_new() mallocs one c7 per SV caller and
// returns it as a chandle; every later call passes the chandle back so C knows WHICH counter.
#include "svdpi.h"
#include <stdio.h>
#include <stdlib.h>

typedef struct { unsigned char cnt; } c7;     // the state of ONE counter instance
static int live = 0;                          // how many c7 objects exist (leak detector)

extern "C" {
void* counter7_new(void) {
  c7* c = (c7*)malloc(sizeof(c7));
  c->cnt = 0;
  live++;
  return c;                                   // becomes an SV chandle
}
void counter7_free(void* inst) { if (inst) { free(inst); live--; } }
int  counter7_live(void) { return live; }

// chandle arrives as void*: cast it back. A null chandle is a TB bug, so refuse it loudly.
int counter7(void* inst, svBitVecVal* count, const svBitVecVal* i,
             const svBit reset, const svBit load) {
  if (!inst) { printf("LOG cerr counter7 called with a null chandle\n"); return -1; }
  c7* c = (c7*)inst;
  if (reset)     c->cnt = 0;
  else if (load) c->cnt = *i;
  else           c->cnt++;
  c->cnt &= 0x7f;
  *count = c->cnt;
  return 0;
}
}
