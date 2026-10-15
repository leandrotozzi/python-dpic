// C side of strings.sv. Rules (IEEE 1800-2023 Annex H):
//  - input string  -> const char*, valid ONLY during the call (copy it if you keep it).
//  - returned / output string -> C owns the memory; SV copies it; C must keep it valid
//    at least until control returns to SV (so: static or heap, never a stack array).
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "svdpi.h"
extern "C" {

int c_strlen(const char* s) { return (int)strlen(s); }

const char* hex_static(int v) {                         // Sample 12.30
  static char s[12];
  snprintf(s, sizeof s, "%08x", v);
  return s;
}

const char* hex_ring(int v) {                           // Sample 12.31, simplified
  static char ring[16][12];
  static int idx = 0;
  char* s = ring[idx++ % 16];
  snprintf(s, 12, "%08x", v);
  return s;
}

void name_of(int code, const char** name) {             // output string -> const char**
  static const char* names[] = {"IDLE", "BUSY", "DONE"};
  *name = (code >= 0 && code < 3) ? names[code] : "???";
}

void upcase(const char** s) {                           // inout: read *s, point it elsewhere
  static char buf[64];
  snprintf(buf, sizeof buf, "%s", *s);
  for (char* p = buf; *p; p++) *p = (char)toupper((unsigned char)*p);
  *s = buf;
}

static char* saved = NULL;
void keep(const char* s) { free(saved); saved = strdup(s); }   // copy, never keep the pointer
const char* kept(void) { return saved ? saved : ""; }

}
