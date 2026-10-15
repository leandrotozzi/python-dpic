#include "svdpi.h"
#include "Vtop__Dpi.h"
void c_run(void) {
  int a = shift_build(), b = shift_build(), c = shift_build();
  shift_sv(a, 0x1, 4);
  shift_sv(b, 0x100, -8);
  shift_sv(c, 0xdeadbeef, 0);
  shift_print(a); shift_print(b); shift_print(c);
}
