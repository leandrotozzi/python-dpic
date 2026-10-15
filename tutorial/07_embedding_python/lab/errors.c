/* Step 07, experiment "errors" (+ refcount measurements). */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdio.h>

static PyObject *f_divide, *f_make, *f_blocks, *f_format;

int err_init(void) {
  Py_Initialize();
  PyObject *path = PySys_GetObject("path"), *dir = PyUnicode_FromString("py");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *m = PyImport_ImportModule("errs"), *tb = PyImport_ImportModule("traceback");
  if (!m || !tb) { PyErr_Print(); return -1; }
  f_divide = PyObject_GetAttrString(m, "divide");
  f_make = PyObject_GetAttrString(m, "make");
  f_blocks = PyObject_GetAttrString(m, "blocks");
  f_format = PyObject_GetAttrString(tb, "format_exception");
  Py_DECREF(m); Py_DECREF(tb);
  return 0;
}

void err_fin(void) {
  Py_CLEAR(f_divide); Py_CLEAR(f_make); Py_CLEAR(f_blocks); Py_CLEAR(f_format);
  Py_FinalizeEx();
}

/* Take the pending exception (clears the indicator), format it like the REPL
   would, and hand the text to SV through an exported function. */
static void report(const char *where) {
  PyObject *exc = PyErr_GetRaisedException();                 /* 3.12+: one object, new ref */
  PyObject *lines = PyObject_CallOneArg(f_format, exc);       /* list[str] */
  PyObject *sep = PyUnicode_FromString("");
  PyObject *text = lines ? PyUnicode_Join(sep, lines) : NULL;
  sv_py_error(where, text ? PyUnicode_AsUTF8(text) : "<unformattable exception>");
  Py_XDECREF(text); Py_DECREF(sep); Py_XDECREF(lines); Py_DECREF(exc);
}

int err_divide(int a, int b, int *q) {
  PyObject *r = PyObject_CallFunction(f_divide, "ii", a, b);
  if (!r) { report("divide"); return -1; }
  *q = (int)PyLong_AsLong(r);
  Py_DECREF(r);
  return 0;
}

/* Bug: an error is raised by a conversion and nobody clears it. */
int err_stale(void) {
  PyObject *s = PyUnicode_FromString("not a number");
  long v = PyLong_AsLong(s);                                  /* -1, TypeError pending */
  Py_DECREF(s);
  printf("LOG stale v=%ld pending=%d\n", v, PyErr_Occurred() != NULL);
  PyObject *r = PyObject_CallFunction(f_divide, "ii", 9, 3);  /* called with an error set */
  printf("LOG stale call_result=%s pending_after=%s\n", r ? "obj" : "NULL",
         PyErr_Occurred() ? ((PyTypeObject *)PyErr_Occurred())->tp_name : "none");
  if (!r) {
    PyObject *exc = PyErr_GetRaisedException(), *msg = PyObject_Str(exc);
    printf("LOG stale msg=\"%s\"\n", PyUnicode_AsUTF8(msg));
    Py_DECREF(msg); Py_DECREF(exc);
    fflush(stdout);
    return -1;
  }
  Py_DECREF(r);
  PyErr_Clear();
  return 0;
}

static long blocks(void) {
  PyObject *r = PyObject_CallNoArgs(f_blocks);
  long v = PyLong_AsLong(r);
  Py_DECREF(r);
  return v;
}

/* Allocated-block growth per call: 0 when every new reference is released. */
int rc_blocks_per_call(int n, int leak) {
  long before = blocks();
  for (int i = 0; i < n; i++) {
    PyObject *r = PyObject_CallNoArgs(f_make);                /* new reference */
    if (!leak) Py_DECREF(r);                                  /* leak: forgotten DECREF */
  }
  return (int)((blocks() - before + n / 2) / n);
}

void rc_immortal(void) {
  PyObject *seven = PyLong_FromLong(7), *big = PyLong_FromLong(1000000);
  printf("LOG immortal none=%zd small_int=%zd big_int=%zd\n",
         Py_REFCNT(Py_None), Py_REFCNT(seven), Py_REFCNT(big));
  Py_DECREF(seven); Py_DECREF(big);
}
