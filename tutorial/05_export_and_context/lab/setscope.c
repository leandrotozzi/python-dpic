// Samples 12.48 (fixed: the book says "svGetScope" where it means svSetScope) + scope by name + user data.
#include <stdio.h>
#include <stdlib.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"

static svScope my_scope;                         // a scope handle is just an opaque pointer: keep it

void save_my_scope(void) { my_scope = svGetScope(); }

void c_display(void) {
  printf("LOG c called_from=%s\n", svGetNameFromScope(svGetScope()));
  svScope prev = svSetScope(my_scope);           // returns the previous scope
  printf("LOG c now_in=%s prev=%s\n", svGetNameFromScope(svGetScope()), svGetNameFromScope(prev));
  fflush(stdout);
  sv_display();                                  // runs block's export, not top's
  svSetScope(prev);                              // good manners: restore
}

void by_name(const char* name) {
  svScope s = svGetScopeFromName(name);
  printf("LOG byname name=%s found=%d\n", name, s != NULL);
  fflush(stdout);
  if (s) { svScope prev = svSetScope(s); sv_display(); svSetScope(prev); }
}

// Per-instance C state without a chandle: hang it on the caller's scope.
static int key;                                  // its address is the user-data key
int bump(void) {
  svScope s = svGetScope();
  int* n = (int*)svGetUserData(s, &key);
  if (!n) { n = (int*)calloc(1, sizeof *n); svPutUserData(s, &key, n); }
  return ++*n;
}
