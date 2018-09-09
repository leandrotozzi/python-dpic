#include <svdpi.h>
#include <malloc.h>
#include <veriuser.h>

typedef struct { // Structure to hold counter value
    unsigned char cnt;
} c7;

// Construct a counter structure
void* counter7_new() {
    c7* c = (c7*) malloc(sizeof(c7));
    c->cnt = 0;
    return c;
}

// Run the counter for one cycle
void counter7(c7 *inst,
              svBitVecVal* count,
              const svBitVecVal* i,
              const svBit reset,
              const svBit load) {

    if (reset)     inst->cnt = 0;   // Reset
    else if (load) inst->cnt = *i;  // Load Value
    else           inst->cnt++;     // Count
    inst->cnt &= 0x7f;              // Mask upper bit

    *count = inst->cnt;             // Write to output

    // The C code uses the PLI task io_printf to display debug messages.
    io_printf("C: count=%d, i=%d, reset=%d, load=%d\n",
               *count, *i, reset, load);
}