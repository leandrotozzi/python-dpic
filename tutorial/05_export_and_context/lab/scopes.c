// C side of Samples 12.34/12.35/12.46. printf replaces the book's io_printf (PLI, gone).
#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"   // Verilator-generated prototypes for imports AND exports

void c_display(void) {
  const char* file = "?";
  int line = 0;
  svGetCallerInfo(&file, &line);               // where in SV the import was called from
  printf("LOG c scope=%s caller=%s:%d\n", svGetNameFromScope(svGetScope()), file, line);
  fflush(stdout);
  sv_display();                                // resolves to the export of the CURRENT scope
}
