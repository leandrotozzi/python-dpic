/* Exercise 12: Sample 12.12 with its two latent bugs fixed.
   1. i->bval tested the 25 unused bits too (undetermined per the LRM): mask to 7 bits.
   2. The error paths returned without writing `count`: the SV variable then receives an undetermined
      value. Drive X instead (aval=bval=1 on every bit) so the testbench sees the problem. */
#include <stdio.h>
#include <stdlib.h>
#include "svdpi.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef struct { unsigned char cnt; } c7;
void* counter7_new(void) { c7* c = (c7*)malloc(sizeof(c7)); c->cnt = 0; return c; }

void counter7(void* h, svLogicVecVal* count, const svLogicVecVal* i, const svLogic reset, const svLogic load) {
  c7* inst = (c7*)h;
  if ((reset & 2) || (load & 2) || (i->bval & SV_MASK(7))) {
    printf("LOG c4err Z or X detected on an input\n");
    count->aval = count->bval = SV_MASK(7);   /* 7'bx */
    return;
  }
  if (reset)     inst->cnt = 0;
  else if (load) inst->cnt = (unsigned char)i->aval;
  else           inst->cnt++;
  inst->cnt &= 0x7f;
  count->aval = inst->cnt;
  count->bval = 0;
}
#ifdef __cplusplus
}
#endif
