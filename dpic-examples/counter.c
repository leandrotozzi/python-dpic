#include <svdpi.h>
void counter7(svBitVecVal *o,
              const svBitVecVal *i,
              const svBit reset,
              const svBit load) {

    static unsigned char count = 0; // Static count storage

    if (reset) count = 0;           // Reset 
    else if (load) count = *i;      // Load Value
    else count++;                   // Count
    count &= 0x7f;                  // Mask upper bit       

    *o = count;
}