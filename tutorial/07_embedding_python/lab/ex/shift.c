/* Ex. 12.1: C is only the bridge, the model is exmods.shift(). */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdio.h>

static PyObject *f_shift, *f_naive;

int ex_init(void) {
  Py_Initialize();
  PyObject *path = PySys_GetObject("path"), *dir = PyUnicode_FromString("ex/py");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *m = PyImport_ImportModule("exmods");
  if (!m) { PyErr_Print(); return -1; }
  f_shift = PyObject_GetAttrString(m, "shift");
  f_naive = PyObject_GetAttrString(m, "shift_naive");
  Py_DECREF(m);
  return 0;
}

unsigned int shift_py(unsigned int i, int n, int naive) {
  /* "I" = unsigned int -> Python int (never negative), "i" = int */
  PyObject *r = PyObject_CallFunction(naive ? f_naive : f_shift, "Ii", i, n);
  if (!r) {
    PyObject *exc = PyErr_GetRaisedException(), *msg = PyObject_Str(exc);
    printf("LOG shift_error type=%s msg=\"%s\"\n", Py_TYPE(exc)->tp_name, PyUnicode_AsUTF8(msg));
    Py_DECREF(msg); Py_DECREF(exc);
    return 0xDEADBEEF;
  }
  unsigned int v = (unsigned int)PyLong_AsUnsignedLong(r);
  Py_DECREF(r);
  return v;
}

void ex_fin(void) { Py_CLEAR(f_shift); Py_CLEAR(f_naive); Py_FinalizeEx(); }
