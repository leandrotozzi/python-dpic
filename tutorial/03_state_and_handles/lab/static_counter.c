// Sample 12.7 (corrected): a 7-bit counter whose state lives in a C static variable.
// There is exactly ONE `count` in the whole simulation, no matter how many SV callers.
#include "svdpi.h"
#include <stdio.h>

extern "C" void counter7(svBitVecVal* o, const svBitVecVal* i,
                         const svBit reset, const svBit load) {
  static unsigned char count = 0;   // one copy per process, shared by every caller
  if (reset)     count = 0;
  else if (load) count = *i;
  else           count++;
  count &= 0x7f;                    // 7-bit counter: mask the 8th bit of the char
  *o = count;
}
