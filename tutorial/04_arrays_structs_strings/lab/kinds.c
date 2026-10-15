#include "svdpi.h"
extern "C" int sum_oa(const svOpenArrayHandle h) {
  int s = 0;
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++) s += *(int*)svGetArrElemPtr1(h, i);
  return s;
}
