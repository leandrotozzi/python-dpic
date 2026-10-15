// T8: give the TLM counter a deep copy. The C++ copy constructor does the work;
// counter7_clone is one more extern "C" wrapper.
#include "svdpi.h"
class Counter7 {
 public:
  static int live;
  Counter7() : cnt(0) { live++; }
  Counter7(const Counter7& o) : cnt(o.cnt) { live++; }
  ~Counter7() { live--; }
  void count() { cnt = (cnt + 1) & 0x7f; }
  void load(const svBitVecVal* i) { cnt = *i & 0x7f; }
  int  get() const { return cnt; }
 private:
  unsigned char cnt;
};
int Counter7::live = 0;
static Counter7* obj(void* p) { return static_cast<Counter7*>(p); }
extern "C" {
void* counter7_new(void)                              { return new Counter7; }
void* counter7_clone(void* inst)                      { return new Counter7(*obj(inst)); }
void  counter7_delete(void* inst)                     { delete obj(inst); }
void  counter7_count(void* inst)                      { obj(inst)->count(); }
void  counter7_load(void* inst, const svBitVecVal* i) { obj(inst)->load(i); }
int   counter7_get(void* inst)                        { return obj(inst)->get(); }
int   counter7_live(void)                             { return Counter7::live; }
}
