/* Ex. 12 (bug): `static` gives factorial internal linkage; the linker cannot see it from Vtop. */
extern "C" {
static int factorial(const int i) { return i <= 1 ? 1 : i * factorial(i - 1); }
int expect(void) { return 42; }
int addmul(int a, int b, int* sum) { *sum = a + b; return a * b; }
}
