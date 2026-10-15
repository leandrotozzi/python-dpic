// Sample 12.45, C-driven, with the index returned by mem_build checked against the file's.
#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"

int read_file(const char* fname) {
  FILE* f = fopen(fname, "r");
  if (!f) return 1;
  char cmd;
  int idx, a, b, errs = 0;
  while (fscanf(f, " %c%d", &cmd, &idx) == 2) {
    switch (cmd) {
      case 'M': {
        fscanf(f, "%d", &a);
        int got = mem_build(a);
        if (got != idx) { printf("LOG c error=index file=%d sv=%d\n", idx, got); errs++; }
        break;
      }
      case 'W': fscanf(f, "%d %d", &a, &b); mem_write(idx, a, b); break;
      case 'R': {
        fscanf(f, "%d %d", &a, &b);
        int got = mem_read(idx, a);
        printf("LOG c read mem=%d addr=%d data=%d exp=%d %s\n", idx, a, got, b, got == b ? "ok" : "MISMATCH");
        if (got != b) errs++;
        break;
      }
    }
  }
  fclose(f);
  fflush(stdout);
  return errs;
}
