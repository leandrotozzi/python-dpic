#include "Vtop__Dpi.h"
int gcd(int a, int b, int* steps) {
  *steps = 0;                         /* an output arrives uninitialized: always write it */
  while (b != 0) { int t = a % b; a = b; b = t; (*steps)++; }
  return a;
}
