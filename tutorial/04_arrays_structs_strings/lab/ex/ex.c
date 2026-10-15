// Exercise solutions for step 04 (C side).
#include <stdio.h>
#include <string.h>
#include "svdpi.h"
extern "C" {

// Exercise 1: any size, any range -> walk svLow..svHigh, accumulate in 64 bits.
long long ex1_sum(const svOpenArrayHandle h) {
  long long s = 0;
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++) s += *(int*)svGetArrElemPtr1(h, i);
  return s;
}

// Exercise 2: the numbers you were asked to predict.
void ex2_query(const svOpenArrayHandle h, int* q) {
  q[0] = svLeft(h, 1); q[1] = svRight(h, 1); q[2] = svLow(h, 1); q[3] = svHigh(h, 1);
  q[4] = svIncrement(h, 1); q[5] = svSize(h, 1);
  q[6] = svLeft(h, 2); q[7] = svRight(h, 2); q[8] = svIncrement(h, 2); q[9] = svSize(h, 2);
  q[10] = svDimensions(h); q[11] = svSizeOfArray(h);
}

// Exercise 5: byte -> char (signed!). Cast to unsigned char before shifting.
void ex5_hist(const svOpenArrayHandle data, const svOpenArrayHandle hist) {
  for (int b = svLow(hist, 1); b <= svHigh(hist, 1); b++) *(int*)svGetArrElemPtr1(hist, b) = 0;
  for (int i = svLow(data, 1); i <= svHigh(data, 1); i++) {
    unsigned char v = *(unsigned char*)svGetArrElemPtr1(data, i);
    (*(int*)svGetArrElemPtr1(hist, v >> 4))++;
  }
}

// Exercise 7: dst = [111:64], src = [63:16]; move 48-bit fields as 32 + 16 bit parts.
void ex7_swap_macs(svBitVecVal* h) {
  svBitVecVal dl, dh, sl, shi;
  svGetPartselBit(&dl, h, 64, 32); svGetPartselBit(&dh, h, 96, 16);
  svGetPartselBit(&sl, h, 16, 32); svGetPartselBit(&shi, h, 48, 16);
  svPutPartselBit(h, sl, 64, 32);  svPutPartselBit(h, shi, 96, 16);
  svPutPartselBit(h, dl, 16, 32);  svPutPartselBit(h, dh, 48, 16);
}

// Exercise 9: fixed-size array + explicit count.
int ex9_sum_n(const int* buf, int n) {
  int s = 0;
  for (int k = 0; k < n; k++) s += buf[k];
  return s;
}

// Exercise 10: c = a x b with arbitrary ranges; -1 if the shapes do not match.
int ex10_matmul(const svOpenArrayHandle a, const svOpenArrayHandle b, const svOpenArrayHandle c) {
  int n = svSize(a, 1), k = svSize(a, 2), m = svSize(b, 2);
  if (svSize(b, 1) != k || svSize(c, 1) != n || svSize(c, 2) != m) return -1;
  for (int i = 0; i < n; i++)
    for (int j = 0; j < m; j++) {
      int s = 0;
      for (int t = 0; t < k; t++)
        s += *(int*)svGetArrElemPtr2(a, svLow(a, 1) + i, svLow(a, 2) + t) *
             *(int*)svGetArrElemPtr2(b, svLow(b, 1) + t, svLow(b, 2) + j);
      *(int*)svGetArrElemPtr2(c, svLow(c, 1) + i, svLow(c, 2) + j) = s;
    }
  return 0;
}

// Exercise 11: wide elements -> always go through the canonical copy functions.
void ex11_xor(const svOpenArrayHandle w, svBitVecVal* x) {
  svBitVecVal e[4];
  memset(x, 0, 4 * sizeof(svBitVecVal));
  for (int i = svLow(w, 1); i <= svHigh(w, 1); i++) {
    svGetBitArrElem1VecVal(e, w, i);
    for (int k = 0; k < 4; k++) x[k] ^= e[k];
  }
}

// Exercise 12 (book Ex. 12.1 applied to an array): n>0 left, n<0 right, |n|>=32 -> 0.
void ex12_shift_all(const svOpenArrayHandle v, int n) {
  for (int i = svLow(v, 1); i <= svHigh(v, 1); i++) {
    unsigned* p = (unsigned*)svGetArrElemPtr1(v, i);
    if (n >= 32 || n <= -32) *p = 0;                  // C: shifting by >= width is UB
    else if (n > 0) *p <<= n;
    else if (n < 0) *p >>= -n;
  }
}

}
