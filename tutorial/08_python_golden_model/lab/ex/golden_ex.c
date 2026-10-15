/* Exercise solutions: the bridge extended with generic objects and signed wide ints.
 * Reuses callable()/fail()/err from the step's bridge by including it (one translation unit). */
#include "../golden_py.c"

/* Build a tuple of Python ints from an open array of longint. */
static PyObject* args_tuple(const svOpenArrayHandle args) {
  int n = svSize(args, 1);
  const long long* a = (const long long*)svGetArrayPtr(args);
  PyObject* t = PyTuple_New(n);
  for (int i = 0; i < n; i++) PyTuple_SET_ITEM(t, i, PyLong_FromLongLong(a[i]));
  return t;
}

#ifdef __cplusplus
extern "C" {
#endif

/* Ex. 9: any Python object as a chandle. The chandle owns one strong reference. */
void* py_new(const char* mod, const char* cls, const svOpenArrayHandle args) {
  PyObject* c = callable(mod, cls);
  if (!c) return NULL;
  PyObject* t = args_tuple(args);
  PyObject* obj = PyObject_Call(c, t, NULL);
  Py_DECREF(t);
  if (!obj) fail(cls);
  return obj;
}

long long py_call_method_i64(void* obj, const char* method, const svOpenArrayHandle args) {
  if (!obj) return 0;
  PyObject* m = PyObject_GetAttrString((PyObject*)obj, method);
  if (!m) { fail(method); return 0; }
  PyObject* t = args_tuple(args);
  PyObject* r = PyObject_Call(m, t, NULL);
  Py_DECREF(t); Py_DECREF(m);
  long long v = r ? PyLong_AsLongLong(r) : 0;
  if (!r || PyErr_Occurred()) { fail(method); v = 0; }
  Py_XDECREF(r);
  return v;
}

void py_free(void* obj) { Py_XDECREF((PyObject*)obj); }

/* Ex. 10: signed 100-bit. Sign-extend bit 99 into the whole buffer, then read it as SIGNED. */
void py_neg100(const svBitVecVal* a, svBitVecVal* y) {
  svBitVecVal w[4];
  memcpy(w, a, 16);
  w[3] = (w[3] & 0x8) ? (w[3] | 0xFFFFFFF0u) : (w[3] & 0xF);
  PyObject* f = callable("ex_models", "neg100");            /* FIRST: it initializes Python */
  PyObject* pa = f ? PyLong_FromNativeBytes(w, 16, Py_ASNATIVEBYTES_LITTLE_ENDIAN) : NULL;   /* signed buffer */
  PyObject* r = pa ? PyObject_CallOneArg(f, pa) : NULL;
  memset(y, 0, 16);
  /* write signed into 16 bytes; the value must fit in 100 bits: top 29 bits all equal to bit 99 */
  Py_ssize_t need = r ? PyLong_AsNativeBytes(r, y, 16, Py_ASNATIVEBYTES_LITTLE_ENDIAN) : -1;
  if (need < 0) fail("neg100");
  else if (need > 16 || ((y[3] >> 3) != 0 && (y[3] >> 3) != 0x1FFFFFFFu))
    snprintf(err, sizeof err, "neg100: result does not fit in 100 signed bits");
  y[3] &= 0xF;                                               /* keep the unused top bits clean */
  Py_XDECREF(r); Py_XDECREF(pa);
}

#ifdef __cplusplus
}
#endif
