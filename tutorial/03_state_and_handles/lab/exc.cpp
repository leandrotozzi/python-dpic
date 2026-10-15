// A C++ model that throws. Without the try/catch in safe mode the exception reaches the
// Verilator-generated caller: 35.5.1.6 says undefined; on this platform the process aborts.
#include <cstdio>
#include <stdexcept>
static int step(int x, bool fail) {
    if (fail) throw std::runtime_error("model_step: bad input");
    return 10 * x;
}
extern "C" int model_step(int x, unsigned char fail) {
#ifdef SAFE
    try { return step(x, fail); }
    catch (const std::exception& e) { std::fprintf(stderr, "C++ error: %s\n", e.what()); return -1; }
#else
    return step(x, fail);
#endif
}
