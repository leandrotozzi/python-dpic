#include <stdio.h>
#include "svdpi.h"
extern "C" {
void w_out(const svOpenArrayHandle h) {
  printf("LOG c_sees out0=%d\n", *(int*)svGetArrElemPtr1(h, 0));   // reading an output: meaningless
  *(int*)svGetArrElemPtr1(h, 1) = 7;
}
void w_io(const svOpenArrayHandle h) { *(int*)svGetArrElemPtr1(h, 1) = 7; }
void w_outf(int* c) { c[1] = 7; }
}
