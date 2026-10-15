/* Spear Sample 12.12 (4-state counter7), ported: io_printf -> printf, c7* -> void* for the chandle. */
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
  if (reset & 0x2) { printf("LOG c4err Z or X detected on reset\n"); return; }  /* bval bit of a scalar */
  if (load & 0x2)  { printf("LOG c4err Z or X detected on load\n");  return; }
  if (i->bval) { printf("LOG c4err Z or X detected on i\n"); return; }       /* as in the book: see Exercise 12 */
  if (reset)     inst->cnt = 0;
  else if (load) inst->cnt = (unsigned char)i->aval;
  else           inst->cnt++;
  inst->cnt &= 0x7f;
  count->aval = inst->cnt;   /* write both planes: bval = 0 means "no X/Z" */
  count->bval = 0;
}
#ifdef __cplusplus
}
#endif
