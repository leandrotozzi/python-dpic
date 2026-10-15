// C side of openarr.sv: open array queries and element access.
#include <stdio.h>
#include "svdpi.h"
extern "C" {

// Sample 12.23, corrected: loop to svSize(h,1)-1 (the book writes <=, one past the end).
void fib_oa(const svOpenArrayHandle h) {
  svBitVecVal* d = (svBitVecVal*)svGetArrayPtr(h);   // contiguous storage, or NULL
  int n = svSize(h, 1);
  d[0] = 1; d[1] = 1;
  for (int i = 2; i < n; i++) d[i] = d[i-1] + d[i-2];
}

void query(const svOpenArrayHandle h, int* q) {
  q[0] = svLeft(h, 1);  q[1] = svRight(h, 1);
  q[2] = svLow(h, 1);   q[3] = svHigh(h, 1);
  q[4] = svIncrement(h, 1);
  q[5] = svSize(h, 1);
  q[6] = svLeft(h, 2);  q[7] = svRight(h, 2);  q[8] = svSize(h, 2);
  q[9] = svDimensions(h);
  q[10] = svSizeOfArray(h);                            // bytes; 0 if not C layout (Verilator)
}

// Sample 12.25: walk with svLow..svHigh, element pointer by SV index.
void mydisplay(const svOpenArrayHandle h) {
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++)
    for (int j = svLow(h, 2); j <= svHigh(h, 2); j++) {
      int* a = (int*)svGetArrElemPtr2(h, i, j);
      if (i == 6 && j == 3) printf("LOG c_sees a63=%d\n", *a);
      *a = i * j;
    }
}

int sum_oa(const svOpenArrayHandle h) {               // works for any range/kind
  int s = 0;
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++) s += *(int*)svGetArrElemPtr1(h, i);
  return s;
}

int has_ptr(const svOpenArrayHandle h)   { return svGetArrayPtr(h) != NULL; }
int has_ptr_b(const svOpenArrayHandle h) { return svGetArrayPtr(h) != NULL; }

// Which element sits at offset 0 of the flat storage? (row-major, but from which end?)
void flat(const svOpenArrayHandle v, const svOpenArrayHandle m) {
  int* pv = (int*)svGetArrayPtr(v);
  int* pm = (int*)svGetArrayPtr(m);
  printf("LOG flat v0=%d v_last=%d v_at_low=%td m0=%d m1=%d m6=%d\n", pv[0], pv[9],
         (int*)svGetArrElemPtr1(v, svLow(v, 1)) - pv, pm[0], pm[1], pm[6]);
}

// 1-D access function on a 2-D handle: run-time warning + NULL.
int dimcheck(const svOpenArrayHandle m) {
  fflush(stdout);
  return svGetArrElemPtr1(m, 1) == NULL ? -1 : 0;
}

// Index 0 does not exist in [10:1]: the access function returns NULL (+ a warning).
int probe_oob(const svOpenArrayHandle h) {
  fflush(stdout);
  return svGetArrElemPtr1(h, 0) == NULL ? -1 : 0;
}

}
