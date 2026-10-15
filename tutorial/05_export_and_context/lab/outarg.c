#include "svdpi.h"
#include "Vtop__Dpi.h"
void skip_out(int k, int* o) { (void)k; (void)o; }   // BUG on purpose: *o never written
