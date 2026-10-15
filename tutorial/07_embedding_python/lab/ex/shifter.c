/* chandle = a strong reference (PyObject*) owned by the SV side until sh_free(). */
#include <Python.h>
#include "Vtop__Dpi.h"

static PyObject *cls;
static int live;

int sh_init(void) {
  Py_Initialize();
  PyObject *path = PySys_GetObject("path"), *dir = PyUnicode_FromString("ex/py");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *m = PyImport_ImportModule("exmods");
  if (!m) { PyErr_Print(); return -1; }
  cls = PyObject_GetAttrString(m, "Shifter");
  Py_DECREF(m);
  return 0;
}

void *sh_new(unsigned int init) {
  PyObject *obj = PyObject_CallFunction(cls, "I", init);   /* new ref: SV now owns it */
  if (!obj) { PyErr_Print(); return NULL; }
  live++;
  return obj;
}

unsigned int sh_step(void *h, unsigned int i, int n, svBit ld) {
  PyObject *r = PyObject_CallMethod((PyObject *)h, "step", "IiO", i, n, ld ? Py_True : Py_False);
  if (!r) { PyErr_Print(); return 0; }
  unsigned int v = (unsigned int)PyLong_AsUnsignedLong(r);
  Py_DECREF(r);
  return v;
}

int sh_calls(void) {
  PyObject *c = PyObject_GetAttrString(cls, "calls");
  int v = (int)PyLong_AsLong(c);
  Py_DECREF(c);
  return v;
}

void sh_free(void *h) { Py_XDECREF((PyObject *)h); live--; }
int sh_live(void) { return live; }
void sh_fin(void) { Py_CLEAR(cls); Py_FinalizeEx(); }
