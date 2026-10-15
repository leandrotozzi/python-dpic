#include <time.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
int f_gen(int x)  { return x ^ 0x5a; }
int f_pure(int x) { return x ^ 0x5a; }
int f_ctx(int x)  { return x ^ 0x5a; }
int f_ctx_export(int x) { return sv_inc(x) ^ 0x5a; }
long long now_ns(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return (long long)t.tv_sec * 1000000000LL + t.tv_nsec;
}
