/* Step 01: C side of hello.sv. Verilator compiles this file as C++, so every function SV
   imports must have C linkage: wrap the definitions in extern "C" (or include V<top>__Dpi.h, see hdr.c). */
#ifdef __cplusplus
extern "C" {
#endif

int factorial(const int i) {        /* Sample 12.5: const input, the compiler rejects writes to i */
  return i <= 1 ? 1 : i * factorial(i - 1);
}

int expect(void) { return 42; }     /* C name "expect", SV name fexpect */

int addmul(int a, int b, int* sum) { /* output int -> int*: C writes through the pointer */
  *sum = a + b;
  return a * b;
}

#ifdef __cplusplus
}
#endif
