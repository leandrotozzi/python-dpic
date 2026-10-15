// C side of fib.sv. Verilator compiles .c as C++, hence extern "C".
#include <stdio.h>
#include <string.h>
#include "svdpi.h"
extern "C" {

void fib2(svBitVecVal data[20]) {           // same as svBitVecVal* data
  data[0] = 1;
  data[1] = 1;
  for (int i = 2; i < 20; i++) data[i] = data[i-1] + data[i-2];
}

void fib4(svLogicVecVal data[20]) {         // 4-state: write aval AND bval
  data[0].aval = 1; data[0].bval = 0;
  data[1].aval = 1; data[1].bval = 0;
  for (int i = 2; i < 20; i++) {
    data[i].aval = data[i-1].aval + data[i-2].aval;
    data[i].bval = 0;                       // forget this and you get X/Z (on a 4-state simulator)
  }
}

// Bug on purpose: bval left at all-ones. IEEE: aval/bval = 0/1 -> Z, 1/1 -> X.
// Verilator is 2-state and ignores bval, so it silently reads aval.
void fib4_bad(svLogicVecVal data[20]) {
  for (int i = 0; i < 20; i++) { data[i].aval = i; data[i].bval = 0xFFFFFFFFu; }
}

int sum8(const int* v) {
  int s = 0;
  for (int i = 0; i < 8; i++) s += v[i];
  return s;
}

void bytes_in(const char* b, int* packed_le) { // byte b[4] -> 4 consecutive chars
  memcpy(packed_le, b, 4);                  // little-endian host: b[0] is the LSB
}

}
