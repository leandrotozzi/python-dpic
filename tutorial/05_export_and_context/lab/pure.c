#include "svdpi.h"
#include "Vtop__Dpi.h"
static int np, ng;
int sq_pure(int x) { np++; return x * x; }
int sq_gen(int x)  { ng++; return x * x; }
int calls_pure(void) { return np; }
int calls_gen(void)  { return ng; }
