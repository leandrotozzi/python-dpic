/* Wall-clock helper for the measurements (not part of the golden-model contract). */
#include <time.h>
#include "Vtop__Dpi.h"
double wall_s(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec + 1e-9 * ts.tv_nsec;
}
