/* Baseline for the cost measurements: the cheapest possible DPI call. */
#include "Vtop__Dpi.h"
int dpi_nop(int x) { return x + 1; }
