// A function with hidden state (a call counter) that is imported as `pure`. `pure` promises
// "result depends only on inputs, no side effects", so the simulator may drop or merge calls.
#include <stdio.h>
static int calls = 0;
extern "C" int bump(int x) { calls++; return x + 1; }
extern "C" int bump_calls(void) { return calls; }
