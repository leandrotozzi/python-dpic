/* Ex: PyRun_String in eval mode against a persistent globals dict with `math` imported. */
#include <Python.h>
#include "Vtop__Dpi.h"

static PyObject *globals;

int py_eval_init(void) {
  Py_Initialize();
  globals = PyDict_New();
  PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());   /* borrowed, SetItem INCREFs */
  PyObject *math = PyImport_ImportModule("math");
  PyDict_SetItemString(globals, "math", math);
  Py_DECREF(math);
  return 0;
}

static int fail(void) {                        /* one-line message: "TypeError: must be real number, not str" */
  PyObject *exc = PyErr_GetRaisedException();
  PyObject *msg = PyUnicode_FromFormat("%s: %S", Py_TYPE(exc)->tp_name, exc);
  sv_py_error(PyUnicode_AsUTF8(msg));
  Py_DECREF(msg); Py_DECREF(exc);
  return -1;
}

int py_eval(const char *expr, double *r) {
  PyObject *v = PyRun_String(expr, Py_eval_input, globals, globals);
  if (!v) return fail();
  double d = PyFloat_AsDouble(v);              /* accepts int and float; str -> TypeError */
  Py_DECREF(v);
  if (d == -1.0 && PyErr_Occurred()) return fail();
  *r = d;
  return 0;
}

void py_eval_fin(void) { Py_CLEAR(globals); Py_FinalizeEx(); }
