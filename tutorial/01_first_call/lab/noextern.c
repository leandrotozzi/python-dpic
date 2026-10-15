/* BUG: no extern "C" and no header. Verilator compiles .c as C++, so these names get
   C++-mangled (e.g. __Z9factoriali) and the linker cannot find "factorial". */
int factorial(const int i) { return i <= 1 ? 1 : i * factorial(i - 1); }
int expect(void) { return 42; }
int addmul(int a, int b, int* sum) { *sum = a + b; return a * b; }
