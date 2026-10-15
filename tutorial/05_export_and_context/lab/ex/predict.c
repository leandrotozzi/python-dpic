#include <stdio.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
static svScope pinned;
void pin(void) { pinned = svGetScopeFromName("top.m"); }
void hop(void) {
  if (pinned) svSetScope(pinned);
  who();
}
