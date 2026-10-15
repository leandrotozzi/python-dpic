extern "C" int factorial(const int i) { return i <= 1 ? 1 : i * factorial(i - 1); }
