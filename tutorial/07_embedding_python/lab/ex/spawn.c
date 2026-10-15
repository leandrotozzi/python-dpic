/* Ex: process per call (book §12.9) vs embedded interpreter. */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdlib.h>
#include <sys/wait.h>          /* the book's <wait.h> is Linux-only */
#include <time.h>

static double now_us(void) {
  struct timespec t;
  clock_gettime(CLOCK_MONOTONIC, &t);
  return t.tv_sec * 1e6 + t.tv_nsec / 1e3;
}

int call_cmd(const char *cmd) {
  int status = system(cmd);      /* macOS WEXITSTATUS needs an lvalue (Sample 12.52 passes an rvalue) */
  return WEXITSTATUS(status);
}

double spawn_us(int n) {
  double t0 = now_us();
  for (int i = 0; i < n; i++) call_cmd("python3 -c 'pass'");
  return (now_us() - t0) / n;
}

double embed_us(int n) {
  Py_Initialize();
  PyObject *b = PyImport_ImportModule("builtins"), *f = PyObject_GetAttrString(b, "abs");
  double t0 = now_us();
  for (int i = 0; i < n; i++) {
    PyObject *r = PyObject_CallFunction(f, "i", -i);
    Py_DECREF(r);
  }
  double us = (now_us() - t0) / n;
  Py_DECREF(f); Py_DECREF(b);
  Py_FinalizeEx();
  return us;
}
