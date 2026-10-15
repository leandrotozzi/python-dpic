/* BUG: addmul is imported in hello.sv but never defined. */
extern "C" {
int factorial(const int i) { return i <= 1 ? 1 : i * factorial(i - 1); }
int expect(void) { return 42; }
}
