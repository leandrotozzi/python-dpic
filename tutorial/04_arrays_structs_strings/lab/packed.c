// C side of packed.sv.
#include <stdio.h>
#include <string.h>
#include "svdpi.h"
extern "C" {

// Sample 12.27, corrected: <= svHigh (the book's < skips the last element).
void view_pack(const svOpenArrayHandle h) {
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++) {
    unsigned long long v = *(unsigned long long*)svGetArrElemPtr1(h, i);
    if (i <= 2 || i == 9) printf("LOG c b64_%d=%016llx\n", i, v);
  }
}

// Wide elements: copy through the canonical form (svBitVecVal words, LSW first).
void wide_sum(const svOpenArrayHandle h, svBitVecVal* total) {
  unsigned long long carry = 0;
  svBitVecVal e[4], acc[4] = {0, 0, 0, 0};             // 100 bits -> 4 words
  for (int i = svLow(h, 1); i <= svHigh(h, 1); i++) {
    svGetBitArrElem1VecVal(e, h, i);
    carry = 0;
    for (int k = 0; k < 4; k++) {
      unsigned long long s = (unsigned long long)acc[k] + e[k] + carry;
      acc[k] = (svBitVecVal)s;
      carry = s >> 32;
    }
  }
  acc[3] &= 0xF;                                        // keep 100 bits (3*32 + 4)
  memcpy(total, acc, sizeof acc);
}

void put_wide(const svOpenArrayHandle h) {             // write element 1 = all ones in bits 99..96
  svBitVecVal v[4] = {0xCAFEF00Du, 0, 0, 0xF};
  svPutBitArrElem1VecVal(h, v, 1);
}

// How many bytes does each element take? (svSizeOfArray / svSize)
int layout(const svOpenArrayHandle b, const svOpenArrayHandle s,
           const svOpenArrayHandle q, const svOpenArrayHandle w) {
  printf("LOG layout b8=%d s13=%d q64=%d w100=%d\n",
         svSizeOfArray(b) / svSize(b, 1), svSizeOfArray(s) / svSize(s, 1),
         svSizeOfArray(q) / svSize(q, 1), svSizeOfArray(w) / svSize(w, 1));
  return 0;
}

void logic_get(const svOpenArrayHandle l, int* aval, int* bval) {
  svLogicVecVal v;
  v.bval = 0xDEAD;                                      // poison: see if it is overwritten
  svGetLogicArrElem1VecVal(&v, l, 1);
  *aval = v.aval; *bval = v.bval;
}

// Bug on purpose: treats the element storage as svBitVecVal (4 bytes).
// Verilator stores bit[7:0] elements in 1 byte, so this reads 4 neighbors at once.
int raw8(const svOpenArrayHandle b) {
  return *(svBitVecVal*)svGetArrElemPtr1(b, 0);
}

int bits(const svOpenArrayHandle m) {                  // 1-bit elements: svGetBitArrElem1
  int n = 0;
  for (int i = svLow(m, 1); i <= svHigh(m, 1); i++) n += svGetBitArrElem1(m, i);
  return n;
}

}
