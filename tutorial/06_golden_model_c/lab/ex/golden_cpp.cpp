// Exercise 9: the same golden_pkg contract implemented with C++ classes. The SV side does not
// change: link this file instead of golden.c. Step 08 does exactly this with Python.
#include <array>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include "svdpi.h"
#include "Vtop__Dpi.h"   // declares the imports with C linkage, so the definitions below get it too

namespace {
class Crc32 {
  static std::array<uint32_t, 256> make() {
    std::array<uint32_t, 256> t{};
    for (uint32_t i = 0; i < 256; i++) {
      uint32_t s = i;
      for (int k = 0; k < 8; k++) s = (s & 1) ? (s >> 1) ^ 0xEDB88320u : s >> 1;
      t[i] = s;
    }
    return t;
  }
 public:
  static inline const std::array<uint32_t, 256> tab = make();
  uint32_t s = 0xFFFFFFFFu;
  uint32_t push(uint8_t b) { s = (s >> 8) ^ tab[(s ^ b) & 0xFF]; return ~s; }
};

class Fir8 {
  int16_t c[8], d[8] = {};
 public:
  explicit Fir8(const short* coef) { for (int k = 0; k < 8; k++) c[k] = coef[k]; }
  int16_t step(int16_t x) {
    int64_t acc = int64_t(c[0]) * x;
    for (int k = 1; k < 8; k++) acc += int64_t(c[k]) * d[k - 1];
    int64_t r = (acc + (1 << 14)) >> 15;
    for (int k = 7; k > 0; k--) d[k] = d[k - 1];
    d[0] = x;
    return int16_t(r > 32767 ? 32767 : r < -32768 ? -32768 : r);
  }
};
}  // namespace

// The chandle is the object's address; the C ABI wrappers are one line each.
void* crc32_new() { return new Crc32; }
void  crc32_free(void* h) { delete static_cast<Crc32*>(h); }
void  crc32_clear(void* h) { static_cast<Crc32*>(h)->s = 0xFFFFFFFFu; }
unsigned int crc32_update(void* h, unsigned char b) { return static_cast<Crc32*>(h)->push(b); }
unsigned int crc32_msg(const svOpenArrayHandle m, int len) {
  if (len < 0 || len > svSize(m, 1)) { std::fprintf(stderr, "crc32_msg: bad len %d\n", len); std::abort(); }
  Crc32 c;
  uint32_t r = ~c.s;                                   // CRC of the empty message
  for (int i = 0; i < len; i++) r = c.push(*static_cast<const uint8_t*>(svGetArrElemPtr1(m, svLow(m, 1) + i)));
  return r;
}
void* fir8_new(const short* coef) { return new Fir8(coef); }
void  fir8_free(void* h) { delete static_cast<Fir8*>(h); }
short fir8_step(void* h, short x) { return static_cast<Fir8*>(h)->step(x); }
void  fir8_block(void* h, const svOpenArrayHandle x, const svOpenArrayHandle y, int n) {
  for (int i = 0; i < n; i++)
    *static_cast<short*>(svGetArrElemPtr1(y, svLow(y, 1) + i)) =
        static_cast<Fir8*>(h)->step(*static_cast<const short*>(svGetArrElemPtr1(x, svLow(x, 1) + i)));
}
