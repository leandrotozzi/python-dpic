/* Step 07, experiment "buffering". Two independent buffers write to fd 1:
   C stdio (used by $display) and Python's sys.stdout (an io.TextIOWrapper). */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdio.h>

int buf_init(int unbuffered) {
  PyConfig cfg;
  PyConfig_InitPythonConfig(&cfg);
  cfg.buffered_stdio = !unbuffered;           /* 0 == python -u */
  PyStatus st = Py_InitializeFromConfig(&cfg);
  PyConfig_Clear(&cfg);
  return PyStatus_Exception(st) ? -1 : 0;
}

void buf_say(int i, int py_flush, int c_flush) {
  if (c_flush) fflush(stdout);                /* push pending $display text first */
  char code[96];
  snprintf(code, sizeof code, "print('PY %d', flush=%s)", i, py_flush ? "True" : "False");
  PyRun_SimpleString(code);
}

void buf_fin(void) { fflush(stdout); Py_FinalizeEx(); }
