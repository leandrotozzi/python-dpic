#include "Vtop__Dpi.h"
/* __builtin_popcount is not a real symbol (the compiler inlines it), so it cannot be imported
   directly the way pow() can: it needs this one-line wrapper. */
int popcount32(unsigned int x) { return __builtin_popcount(x); }
