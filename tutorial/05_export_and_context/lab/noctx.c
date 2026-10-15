#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
void touch(void) {}
void call_export(void) {
  svScope s = svGetScope();
  printf("LOG c scope=%s\n", s ? svGetNameFromScope(s) : "NULL");
  fflush(stdout);
  sv_hello();
}
