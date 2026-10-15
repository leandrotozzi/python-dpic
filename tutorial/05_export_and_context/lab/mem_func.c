// Sample 12.37 with the error checking the book removed, and without the `while (!feof())` bug.
#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"

int read_file(const char* fname) {
  FILE* f = fopen(fname, "r");
  if (!f) { printf("LOG c error=cannot_open file=%s\n", fname); return 1; }
  char cmd;
  int a, b, errs = 0;
  while (fscanf(f, " %c", &cmd) == 1) {          // " %c" skips whitespace/newlines; stops at EOF
    switch (cmd) {
      case 'M': fscanf(f, "%d", &a);         mem_build(a);    break;
      case 'W': fscanf(f, "%d %d", &a, &b);  mem_write(a, b); break;
      case 'R': {
        fscanf(f, "%d %d", &a, &b);
        int got = mem_read(a);
        printf("LOG c read addr=%d data=%d exp=%d\n", a, got, b);
        if (got != b) errs++;
        break;
      }
      default: printf("LOG c error=bad_cmd cmd=%c\n", cmd); errs++;
    }
  }
  fclose(f);
  fflush(stdout);
  return errs;
}
