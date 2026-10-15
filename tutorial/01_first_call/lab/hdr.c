/* Same C code as hello.c, but no extern "C" here: the Verilator-generated prototype header
   declares every import with C linkage, and a later definition inherits it. It also makes the
   compiler check each definition against the SV import (see mismatch_hdr.c). */
#include "Vtop__Dpi.h"

int factorial(const int i) { return i <= 1 ? 1 : i * factorial(i - 1); }
int expect(void) { return 42; }
int addmul(int a, int b, int* sum) { *sum = a + b; return a * b; }
