#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
// Imported task: per IEEE 1800 Annex H it returns int (1 = "I was disabled"), 0 normally.
int c_task(int n) {
  for (int i = 0; i < n; i++) {
    int o;
    sv_task(i, &o);          // exported task: LRM says it returns int too; Verilator's header says void
    printf("LOG c i=%d o=%d\n", i, o);
  }
  printf("LOG c disabled_state=%d\n", svIsDisabledState());
  fflush(stdout);
  return 0;
}
