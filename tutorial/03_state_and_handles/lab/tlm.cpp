// Samples 12.15 + 12.16 (+ destroy): a transaction-level C++ counter. SV calls methods
// (count/load/reset/get) instead of driving signals every clock.
#include "svdpi.h"

class Counter7 {
 public:
  static int live;
  Counter7() : cnt(0) { live++; }
  ~Counter7() { live--; }
  void count() { cnt = (cnt + 1) & 0x7f; }
  void load(const svBitVecVal* i) { cnt = *i & 0x7f; }
  void reset() { cnt = 0; }
  int  get() const { return cnt; }
 private:
  unsigned char cnt;
};
int Counter7::live = 0;

static Counter7* obj(void* inst) { return static_cast<Counter7*>(inst); }

extern "C" {
void* counter7_new(void)                              { return new Counter7; }
void  counter7_delete(void* inst)                     { delete obj(inst); }
void  counter7_count(void* inst)                      { obj(inst)->count(); }
void  counter7_load(void* inst, const svBitVecVal* i) { obj(inst)->load(i); }
void  counter7_reset(void* inst)                      { obj(inst)->reset(); }
int   counter7_get(void* inst)                        { return obj(inst)->get(); }
int   counter7_live(void)                             { return Counter7::live; }
}
