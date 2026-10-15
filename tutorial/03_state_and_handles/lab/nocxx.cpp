// BUG version of counter7.cpp: the wrappers lack extern "C", so the C++ compiler mangles
// their names (counter7_new -> __Z12counter7_newv) and the simulator's C call cannot find them.
// Samples 12.13 + 12.14: the same counter as a C++ class. SV can only call functions whose
// address is known at link time, so each method gets an extern "C" static wrapper that takes
// the object pointer (the chandle) as its first argument.
#include "svdpi.h"
#include <stdio.h>
#ifdef CHECK_PROTO
#include "Vtop__Dpi.h"   // earlier extern "C" declarations: the definitions below inherit C linkage
#endif

class Counter7 {
 public:
  static int live;                                     // objects alive right now
  Counter7() : cnt(0) { live++; }
  ~Counter7() { live--; }
  void signal(svBitVecVal* count, const svBitVecVal* i, svBit reset, svBit load) {
    if (reset)     cnt = 0;
    else if (load) cnt = *i;
    else           cnt++;
    cnt &= 0x7f;
    *count = cnt;
  }
 private:
  unsigned char cnt;
};
int Counter7::live = 0;

void* counter7_new(void) { return new Counter7; }
void  counter7_free(void* inst) { delete static_cast<Counter7*>(inst); }   // delete nullptr is a no-op
int   counter7_live(void) { return Counter7::live; }
int   counter7(void* inst, svBitVecVal* count, const svBitVecVal* i, const svBit reset, const svBit load) {
  if (!inst) { printf("LOG cerr counter7 called with a null chandle\n"); return -1; }
  static_cast<Counter7*>(inst)->signal(count, i, reset, load);
  return 0;
}
