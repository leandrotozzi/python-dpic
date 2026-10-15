// C side of the pull model: a tiny iterator over the command file + the expected-value check.
#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"

static FILE* f;
static int errs;
static int expect_q[64], nexp;                   // expected data of reads, in file order
static int nres;

int cmd_open(const char* fname) { f = fopen(fname, "r"); errs = nexp = nres = 0; return f != NULL; }

int cmd_next(char* cmd, int* idx, int* addr, int* data) {
  *addr = *data = 0;                             // outputs C doesn't set arrive in SV as garbage
  if (!f || fscanf(f, " %c%d", cmd, idx) != 2) return 0;
  switch (*cmd) {
    case 'M': fscanf(f, "%d", addr); break;                        // addr carries the size
    case 'W': fscanf(f, "%d %d", addr, data); break;
    case 'R': fscanf(f, "%d %d", addr, &expect_q[nexp++]); break;  // keep exp, SV fills data
  }
  return 1;
}

void cmd_result(int idx, int addr, int data, long long t) {
  int exp = expect_q[nres++];
  printf("LOG c read mem=%d addr=%d data=%d exp=%d t=%lld %s\n", idx, addr, data, exp, t,
         data == exp ? "ok" : "MISMATCH");
  fflush(stdout);
  if (data != exp) errs++;
}

int cmd_close(void) { if (f) fclose(f); f = NULL; return errs; }
