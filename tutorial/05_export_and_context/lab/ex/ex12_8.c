#include "svdpi.h"
#include "Vtop__Dpi.h"
unsigned int shift_c(unsigned int i, int n) {   // context: it calls an export
  unsigned int o;
  shift_sv(i, n, &o);
  return o;
}
