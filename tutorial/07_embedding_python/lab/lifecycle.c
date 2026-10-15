/* Step 07, experiment "lifecycle". */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdio.h>
#include <time.h>

static PyObject *f_say;
static PyObject *stale;        /* raw mode: a pointer cached before finalize */
static int alive;               /* our own guard: 1 between init and fin */

int life_init(void) {
  Py_Initialize();
  PyObject *path = PySys_GetObject("path");
  PyObject *dir = PyUnicode_FromString("py");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *mod = PyImport_ImportModule("life");
  if (!mod) { PyErr_Print(); return -1; }
  f_say = PyObject_GetAttrString(mod, "say");
  Py_DECREF(mod);
  alive = 1;
  return 0;
}

void life_fin(void) {
  fflush(stdout);                                  /* C buffer first: keep SV text ahead */
  stale = f_say;                                   /* raw mode reuses this after finalize */
  Py_CLEAR(f_say);
  alive = 0;
  printf("LOG fin rc=%d\n", Py_FinalizeEx());       /* runs atexit handlers, flushes sys.stdout */
}

int life_say(const char *msg) {
  if (!alive) { printf("LOG guard refused: interpreter not initialized\n"); return -1; }
  PyObject *r = PyObject_CallFunction(f_say, "s", msg);
  if (!r) { PyErr_Print(); return -1; }
  Py_DECREF(r);
  return 0;
}

/* No guard and a stale cached pointer: what happens after Py_FinalizeEx. */
int life_raw_say(const char *msg) {
  (void)msg;
  printf("LOG raw calling a stale object\n"); fflush(stdout);
  PyObject *r = PyObject_CallFunction(stale, "s", "boom");
  return r ? 0 : -1;
}

/* Init + import + finalize n times: what the old python-embedded-C examples did per call. */
double life_cycle_ms(int n, int with_numpy) {
  struct timespec t0, t1;
  int ok = 0;
  clock_gettime(CLOCK_MONOTONIC, &t0);
  for (int i = 0; i < n; i++) {
    Py_Initialize();
    PyObject *m = PyImport_ImportModule(with_numpy ? "numpy" : "json");
    if (m) { ok++; Py_DECREF(m); }
    else   { printf("LOG cycle import failed at i=%d\n", i); PyErr_Print(); }
    Py_FinalizeEx();
  }
  clock_gettime(CLOCK_MONOTONIC, &t1);
  printf("LOG cycle numpy=%d ok=%d of=%d\n", with_numpy, ok, n); fflush(stdout);
  return ((t1.tv_sec - t0.tv_sec) * 1e3 + (t1.tv_nsec - t0.tv_nsec) / 1e6) / n;
}
