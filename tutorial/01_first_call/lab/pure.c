/* ping() is declared pure in pure.sv but it is not: it increments a counter. */
static int n_calls = 0;
extern "C" {
int ping(int x) { n_calls++; return x; }
int ping_raw(int x) { n_calls++; return x; }
int calls(void) { return n_calls; }
}
