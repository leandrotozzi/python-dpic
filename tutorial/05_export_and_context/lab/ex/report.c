#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
void c_check(int got, int exp) {
  if (got == exp) return;
  const char* file; int line;
  char where[256], msg[128];
  svGetCallerInfo(&file, &line);
  snprintf(where, sizeof where, "%s:%d", file, line);
  snprintf(msg, sizeof msg, "got %d exp %d", got, exp);
  sv_report(where, msg);              // string args: C passes const char*, SV copies it
}
