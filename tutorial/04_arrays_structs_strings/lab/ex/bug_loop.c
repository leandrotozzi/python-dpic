#include <stdio.h>
#include "svdpi.h"
extern "C" int sum_bug(const svOpenArrayHandle h) {
  int s = 0;
  for (int i = 0; i < svSize(h, 1); i++) s += *(int*)svGetArrElemPtr1(h, i);  // BUG: i=0 is not an index of [10:1]
  return s;
}
