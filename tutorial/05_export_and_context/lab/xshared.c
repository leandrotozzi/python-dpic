/* One C symbol `hello`, two SV implementations: the scope decides which one runs. */
#include "svdpi.h"
extern "C" void hello();
extern "C" void call_both() {
    svSetScope(svGetScopeFromName("top.u1")); hello();
    svSetScope(svGetScopeFromName("top.u2")); hello();
}
