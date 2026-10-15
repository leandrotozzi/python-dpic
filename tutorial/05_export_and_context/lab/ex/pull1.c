#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
static FILE* f;
int cmd_open(const char* fname) { f = fopen(fname, "r"); return f != NULL; }
int cmd_next(char* cmd, int* addr, int* data, int* exp) {
  *addr = *data = *exp = 0;
  if (!f || fscanf(f, " %c", cmd) != 1) return 0;
  switch (*cmd) {
    case 'M': fscanf(f, "%d", addr); break;
    case 'W': fscanf(f, "%d %d", addr, data); break;
    case 'R': fscanf(f, "%d %d", addr, exp); break;
  }
  return 1;
}
int cmd_close(void) { if (f) fclose(f); f = NULL; return 0; }
