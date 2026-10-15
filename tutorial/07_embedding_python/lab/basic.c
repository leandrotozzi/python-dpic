/* Step 07, experiment "basic": the minimal correct embedding.
   - Py_Initialize once, extend sys.path, import the module, cache the callables.
   - Every call: build args (new refs) -> call (new ref or NULL) -> convert -> DECREF.
   - Py_FinalizeEx from the SV `final` block. */
#include <Python.h>
#include "Vtop__Dpi.h"          /* Verilator-generated prototypes: catches signature mismatches */
#include <stdio.h>

static PyObject *f_add, *f_hypot, *f_reverse, *f_checksum, *f_whoami;
static PyObject *last_str;      /* keeps the UTF-8 buffer returned to SV alive */

static PyObject *get(PyObject *mod, const char *name) {
  PyObject *f = PyObject_GetAttrString(mod, name);          /* new reference, cached forever */
  if (!f) PyErr_Print();
  return f;
}

int py_init(const char *moddir) {
#ifdef __cplusplus
  printf("LOG lang compiled_as=c++ cplusplus=%ld\n", (long)__cplusplus);   /* Verilator compiles .c with $(CXX) */
#endif
  if (Py_IsInitialized()) return 0;
  Py_Initialize();
  PyObject *path = PySys_GetObject("path");                  /* borrowed: do NOT decref */
  PyObject *dir = PyUnicode_FromString(moddir);              /* new */
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *mod = PyImport_ImportModule("toys");             /* new */
  if (!mod) { PyErr_Print(); return -1; }
  f_add = get(mod, "add"); f_hypot = get(mod, "hypot"); f_reverse = get(mod, "reverse");
  f_checksum = get(mod, "checksum"); f_whoami = get(mod, "whoami");
  Py_DECREF(mod);                                            /* sys.modules still holds it */
  return (f_add && f_hypot && f_reverse && f_checksum && f_whoami) ? 0 : -1;
}

void py_fin(void) {
  Py_CLEAR(f_add); Py_CLEAR(f_hypot); Py_CLEAR(f_reverse);
  Py_CLEAR(f_checksum); Py_CLEAR(f_whoami); Py_CLEAR(last_str);
  int rc = Py_FinalizeEx();
  printf("LOG fin rc=%d initialized=%d\n", rc, Py_IsInitialized());
}

int py_add(int a, int b) {
  PyObject *r = PyObject_CallFunction(f_add, "ii", a, b);    /* new ref or NULL */
  if (!r) { PyErr_Print(); return 0; }
  long v = PyLong_AsLong(r);                                 /* 64-bit long on LP64 */
  Py_DECREF(r);
  return (int)v;                                             /* truncation: the bug shown in the guide */
}

/* returns 0 ok, 1 result does not fit in int, -1 Python error */
int py_add_checked(int a, int b, int *sum) {
  PyObject *r = PyObject_CallFunction(f_add, "ii", a, b);
  if (!r) { PyErr_Print(); return -1; }
  int overflow;
  long long v = PyLong_AsLongLongAndOverflow(r, &overflow);
  Py_DECREF(r);
  if (overflow || v < INT32_MIN || v > INT32_MAX) return 1;
  *sum = (int)v;
  return 0;
}

double py_hypot(double x, double y) {
  PyObject *r = PyObject_CallFunction(f_hypot, "dd", x, y);
  if (!r) { PyErr_Print(); return 0.0; }
  double v = PyFloat_AsDouble(r);
  Py_DECREF(r);
  return v;
}

const char *py_reverse(const char *s) {
  PyObject *r = PyObject_CallFunction(f_reverse, "s", s);    /* "s": UTF-8 C string -> str */
  if (!r) { PyErr_Print(); return ""; }
  Py_XSETREF(last_str, r);                                   /* drop the previous result */
  return PyUnicode_AsUTF8(last_str);                         /* valid while last_str lives */
}

int py_checksum(const svOpenArrayHandle d) {
  int n = svSize(d, 1);
  PyObject *buf = PyBytes_FromStringAndSize(NULL, n);        /* new, writable until shared */
  char *p = PyBytes_AsString(buf);
  for (int i = 0; i < n; i++) p[i] = *(char *)svGetArrElemPtr1(d, svLow(d, 1) + i);
  PyObject *r = PyObject_CallOneArg(f_checksum, buf);
  Py_DECREF(buf);
  if (!r) { PyErr_Print(); return -1; }
  long v = PyLong_AsLong(r);
  Py_DECREF(r);
  return (int)v;
}

long long py_pow2(int n) {
  PyObject *two = PyLong_FromLong(2), *e = PyLong_FromLong(n);
  PyObject *r = PyNumber_Power(two, e, Py_None);             /* 2**n as a Python int */
  Py_DECREF(two); Py_DECREF(e);
  long long v = PyLong_AsLongLong(r);                        /* -1 + OverflowError if too big */
  Py_DECREF(r);
  if (v == -1 && PyErr_Occurred()) {
    PyErr_Clear();
    printf("LOG pow2_overflow n=%d\n", n);
  }
  return v;
}

const char *py_whoami(void) {
  PyObject *r = PyObject_CallNoArgs(f_whoami);
  if (!r) { PyErr_Print(); return ""; }
  Py_XSETREF(last_str, r);
  return PyUnicode_AsUTF8(last_str);
}
