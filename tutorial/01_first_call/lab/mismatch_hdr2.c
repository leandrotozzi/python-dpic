/* Header included, but the definition is NOT in extern "C": C++ treats it as a new overload
   of negate (different parameter type), so it compiles and the C-linkage symbol stays undefined. */
#include "Vtop__Dpi.h"
int negate(int v) { return -v; }
