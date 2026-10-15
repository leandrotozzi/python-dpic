#include "Vtop__Dpi.h"
/* unsigned arithmetic wraps by definition; signed overflow (what 21! does in long long) is UB in C */
long long factorial64(int i) {
  unsigned long long f = 1;
  for (int k = 2; k <= i; k++) f *= (unsigned long long)k;
  return (long long)f;
}
