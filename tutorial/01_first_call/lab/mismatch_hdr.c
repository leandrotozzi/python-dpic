/* Same bug as mismatch.c, but with the generated header included: now it is a compile error. */
#include "Vtop__Dpi.h"
extern "C" int negate(int v) { return -v; }
