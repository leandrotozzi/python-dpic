// Sample 12.9's literal signature: the chandle parameter typed as `c7*` instead of `void*`.
// C linkage carries no parameter types, so this links. Build with -DCHECK_PROTO to include the
// prototype header Verilator generates from the SV imports: then the compiler catches it.
#include "svdpi.h"
#include <stdlib.h>
#ifdef CHECK_PROTO
#include "Vtop__Dpi.h"
#endif

typedef struct { unsigned char cnt; } c7;
static int live = 0;

extern "C" {
void* counter7_new(void) { c7* c = (c7*)malloc(sizeof(c7)); c->cnt = 0; live++; return c; }
void  counter7_free(void* inst) { if (inst) { free(inst); live--; } }
int   counter7_live(void) { return live; }
int   counter7(c7* inst, svBitVecVal* count, const svBitVecVal* i,   // <- c7*, not void*
               const svBit reset, const svBit load) {
  if (reset)     inst->cnt = 0;
  else if (load) inst->cnt = *i;
  else           inst->cnt++;
  inst->cnt &= 0x7f;
  *count = inst->cnt;
  return 0;
}
}
