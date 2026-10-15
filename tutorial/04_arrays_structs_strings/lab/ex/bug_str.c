// Exercise 8 (find the bug): returns a pointer into the stack frame that dies on return.
#include <stdio.h>
#include "svdpi.h"
extern "C" const char* to_hex(int v) {
  char s[12];
  snprintf(s, sizeof s, "%08x", v);
  return s;
}
