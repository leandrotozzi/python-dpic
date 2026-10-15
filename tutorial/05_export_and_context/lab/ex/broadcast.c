#include <stdio.h>
#include <stdlib.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
static int key;                                          // &key identifies "our" user data
void hello(void) {
  int* n = (int*)malloc(sizeof *n);
  *n = 0;
  svPutUserData(svGetScope(), &key, n);
  printf("LOG bcast hello=%s\n", svGetNameFromScope(svGetScope()));
}
int broadcast(int n) {
  svScope home = svGetScope(), s;
  int sum = 0;
  char name[64];
  for (int i = 0; i < n; i++) {
    snprintf(name, sizeof name, "top.gen[%d].u", i);   // the name format is the exercise's trap
    if (!(s = svGetScopeFromName(name))) { printf("LOG bcast missing=%s\n", name); continue; }
    svSetScope(s);
    int* cnt = (int*)svGetUserData(s, &key);
    ++*cnt;
    sum += sv_ping(*cnt);
  }
  svSetScope(home);
  fflush(stdout);
  return sum;
}
