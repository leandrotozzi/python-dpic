/* Ex: every entry point goes through ensure(); init happens on the first call only. */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdlib.h>

static PyObject *f_add;
static int inits;

static int ensure(void) {
  if (f_add) return 0;
  inits++;
  Py_Initialize();
  const char *dirs = getenv("PY_DPI_PATH");
  PyObject *path = PySys_GetObject("path"), *dir = PyUnicode_FromString(dirs ? dirs : ".");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *m = PyImport_ImportModule("toys");
  if (!m) { PyErr_Print(); return -1; }
  f_add = PyObject_GetAttrString(m, "add");
  Py_DECREF(m);
  return f_add ? 0 : -1;
}

int lazy_add(int a, int b) {
  if (ensure()) return 0;
  PyObject *r = PyObject_CallFunction(f_add, "ii", a, b);
  if (!r) { PyErr_Print(); return 0; }
  int v = (int)PyLong_AsLong(r);
  Py_DECREF(r);
  return v;
}

int lazy_inits(void) { return inits; }
void lazy_fin(void) { if (f_add) { Py_CLEAR(f_add); Py_FinalizeEx(); } }
