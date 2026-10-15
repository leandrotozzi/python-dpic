/* Experiment "types": C side of the scalar mapping. Verilator compiles .c files as C++, hence extern "C". */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "svdpi.h"
#ifdef DPI_HDR
#include "Vtop__Dpi.h"   /* the prototypes Verilator generated: the compiler now checks every definition */
#endif
#ifdef SREAL_FIX
typedef double sreal_t;  /* what Verilator actually passes for shortreal */
#else
typedef float sreal_t;   /* what the LRM says (Annex H): shortreal <-> float */
#endif
#ifdef __cplusplus
extern "C" {
#endif

void c_sizes(void) {
  printf("LOG sizeof char=%zu short=%zu int=%zu longlong=%zu float=%zu double=%zu svBit=%zu svLogic=%zu "
         "svBitVecVal=%zu svLogicVecVal=%zu ptr=%zu char_signed=%d\n",
         sizeof(char), sizeof(short), sizeof(int), sizeof(long long), sizeof(float), sizeof(double),
         sizeof(svBit), sizeof(svLogic), sizeof(svBitVecVal), sizeof(svLogicVecVal), sizeof(void*),
         (char)-1 < 0);
  fflush(stdout);
}

/* LRM: byte -> char. Plain char is signed on x86 but UNSIGNED on ARM Linux (see the uchar build). */
char rt_byte(char v) { printf("LOG c_byte v=%d\n", v); return v; }
unsigned char rt_ubyte(unsigned char v) { return v; }
short rt_short(short v) { return v; }
unsigned short rt_ushort(unsigned short v) { return v; }
int rt_int(int v) { return v; }
unsigned int rt_uint(unsigned int v) { return v; }
long long rt_long(long long v) { return v; }
unsigned long long rt_ulong(unsigned long long v) { return v; }
double rt_real(double v) { return v; }
sreal_t rt_sreal(sreal_t v) { printf("LOG c_sreal v=%.17g\n", (double)v); return v; }
svBit rt_bit(svBit v) { return v; }
svLogic rt_logic(svLogic v) { printf("LOG c_logic v=%u\n", v); return v; }

/* string input: a const char* valid ONLY during the call. Copy it if you keep it. */
int c_strlen(const char* s) { return (int)strlen(s); }

/* chandle: an opaque void* that SV stores and hands back. Step 03 goes deep. */
void* c_new_box(int v) { int* p = (int*)malloc(sizeof(int)); *p = v; return p; }
int c_box_get(void* h) { return *(int*)h; }
int c_is_null(void* h) { return h == NULL; }

/* packed bit result of <= 32 bits: returned as svBitVecVal (a uint32_t) */
svBitVecVal rt_bit7(const svBitVecVal* v) { return *v; }

char rt_enum(char v) { printf("LOG c_enum v=%d\n", v); return v; }
#ifdef __cplusplus
}
#endif
