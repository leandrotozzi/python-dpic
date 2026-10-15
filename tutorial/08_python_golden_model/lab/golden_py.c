/* golden_py.c - the Python backend of step 06's contract (../../06_golden_model_c/lab/golden_pkg.sv).
 * It defines exactly the C symbols that golden_pkg.sv imports, the same ones 06's golden.c defines,
 * but each one forwards to golden.py in an embedded CPython (3.13+). Link this file OR golden.c:
 * the testbenches do not change.
 * Python-only extras (wide ints, bug selection, error text, a generic bridge) are declared in
 * py_extra_pkg.sv. Verilator compiles this file as C++.
 *
 * Error policy. A contract violation by the caller (len out of range) aborts, like golden.c does.
 * A Python failure inside the model is printed to stderr at once, kept for py_last_error(), and the
 * call returns 0: the scoreboard then reports a mismatch instead of the simulator crashing. */
#include <Python.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"       /* Verilator-generated prototypes: a signature mismatch is a compile error */

static PyObject* cache;      /* dict "module.func" -> callable (strong refs, dropped at exit) */
static char err[2048];       /* last error, "" if none */

/* Format the pending Python exception into err (keeps the first error until it is read). */
static void fail(const char* where) {
  PyObject* exc = PyErr_GetRaisedException();               /* 3.12+: one object, no type/value/tb triple */
  PyObject* s = exc ? PyObject_Str(exc) : NULL;
  const char* msg = s ? PyUnicode_AsUTF8(s) : "(no message)";
  fprintf(stderr, "golden_py: %s: %s: %s\n", where, exc ? Py_TYPE(exc)->tp_name : "?", msg ? msg : "?");
  if (!err[0]) snprintf(err, sizeof err, "%s: %s: %s", where, exc ? Py_TYPE(exc)->tp_name : "?", msg ? msg : "?");
  Py_XDECREF(s); Py_XDECREF(exc);
  PyErr_Clear();
}

/* The contract has no shutdown call (C needs none), so Python is finalized when the process exits:
 * flushes Python's stdout and runs its atexit hooks. Verilator returns from main() after `final`. */
static void finalize(void) {
  Py_CLEAR(cache);
  if (Py_FinalizeEx() < 0) fprintf(stderr, "golden_py: Py_FinalizeEx failed\n");
}

/* Borrowed reference to module.func, imported and looked up once, then served from the cache. */
static PyObject* callable(const char* mod, const char* func) {
  if (!Py_IsInitialized()) { Py_Initialize(); atexit(finalize); }   /* PYTHONPATH (run.sh) finds golden.py */
  if (!cache && !(cache = PyDict_New())) return NULL;
  char key[256];
  snprintf(key, sizeof key, "%s.%s", mod, func);
  PyObject* f = PyDict_GetItemString(cache, key);           /* borrowed; the dict keeps it alive */
  if (f) return f;
  PyObject* m = PyImport_ImportModule(mod);
  if (!m) { fail(key); return NULL; }
  f = PyObject_GetAttrString(m, func);                      /* new ref */
  Py_DECREF(m);
  if (!f) { fail(key); return NULL; }
  PyDict_SetItemString(cache, key, f);                      /* dict takes its own ref */
  Py_DECREF(f);
  return f;
}

/* A memoryview over simulator memory is only valid during this DPI call. If the model still holds it
 * (stored it, or a numpy.frombuffer view whose .base is it) the refcount is > 1: report it, because
 * that view would read stale simulator memory on the next call. Then release it: later Python access
 * through the memoryview itself raises ValueError instead of reading garbage (numpy views still dangle).
 * ponytail: refcount check misses mv[a:b] slices (they reference the internal buffer, not mv); copy with
 * bytes(mv) in the model if it must keep data. */
static void release(PyObject* mv, const char* where) {
  if (Py_REFCNT(mv) > 1 && !err[0])
    snprintf(err, sizeof err, "%s: model kept a reference to a simulator buffer", where);
  PyObject* r = PyObject_CallMethod(mv, "release", NULL);
  if (!r) fail(where);
  Py_XDECREF(r);
  Py_DECREF(mv);
}

#ifdef __cplusplus
extern "C" {
#endif

/* ---- CRC-32 incremental: the chandle IS a golden.Crc32 instance (one strong ref owned by SV) -- */
void* crc32_new(void) {
  PyObject* cls = callable("golden", "Crc32");
  PyObject* obj = cls ? PyObject_CallNoArgs(cls) : NULL;
  if (cls && !obj) fail("Crc32()");
  return obj;
}
void crc32_free(void* h) { Py_XDECREF((PyObject*)h); }
void crc32_clear(void* h) {
  if (!h) return;
  PyObject* r = PyObject_CallMethod((PyObject*)h, "clear", NULL);
  if (!r) fail("Crc32.clear");
  Py_XDECREF(r);
}
unsigned int crc32_update(void* h, unsigned char b) {
  static PyObject* name;                                    /* interned once: no string build per call */
  if (!h) return 0;
  if (!name) name = PyUnicode_InternFromString("update");
  PyObject* pb = PyLong_FromLong(b);
  PyObject* r = PyObject_CallMethodOneArg((PyObject*)h, name, pb);
  Py_DECREF(pb);
  unsigned int v = r ? (unsigned int)PyLong_AsUnsignedLong(r) : 0;
  if (!r || PyErr_Occurred()) { fail("Crc32.update"); v = 0; }   /* As*() returns -1 on error */
  Py_XDECREF(r);
  return v;
}

/* ---- CRC-32 whole message: zero-copy memoryview of the SV array --------------------------- */
unsigned int crc32_msg(const svOpenArrayHandle msg, int len) {
  if (len < 0 || len > svSize(msg, 1)) {                    /* a contract violation, not a mismatch */
    fprintf(stderr, "crc32_msg: len=%d outside buffer of %d\n", len, svSize(msg, 1));
    abort();
  }
  PyObject* f = callable("golden", "crc32_update");
  if (!f) return 0;
  PyObject* mv = PyMemoryView_FromMemory((char*)svGetArrayPtr(msg), len, PyBUF_READ);
  PyObject* r = PyObject_CallFunction(f, "IO", 0u, mv);     /* running CRC of the empty message is 0 */
  unsigned int v = r ? (unsigned int)PyLong_AsUnsignedLong(r) : 0;
  if (!r || PyErr_Occurred()) { fail("crc32_update"); v = 0; }
  Py_XDECREF(r);
  release(mv, "crc32_update");
  return v;
}

/* ---- FIR: the chandle IS a golden.Fir8 instance ------------------------------------------- */
void* fir8_new(const short* coef) {                         /* input shortint coef[8]: plain C array */
  PyObject* cls = callable("golden", "Fir8");
  if (!cls) return NULL;
  PyObject* c = Py_BuildValue("[hhhhhhhh]", coef[0], coef[1], coef[2], coef[3], coef[4], coef[5], coef[6], coef[7]);
  PyObject* obj = PyObject_CallOneArg(cls, c);              /* new ref -> handed to SV */
  Py_DECREF(c);
  if (!obj) fail("Fir8()");
  return obj;
}

void fir8_free(void* h) { Py_XDECREF((PyObject*)h); }      /* last ref -> Fir8.__del__ runs here */

short fir8_step(void* h, short x) {
  static PyObject* name;
  if (!h) return 0;
  if (!name) name = PyUnicode_InternFromString("step");
  PyObject* px = PyLong_FromLong(x);
  PyObject* r = PyObject_CallMethodOneArg((PyObject*)h, name, px);
  Py_DECREF(px);
  short y = r ? (short)PyLong_AsLong(r) : 0;
  if (!r || PyErr_Occurred()) { fail("Fir8.step"); y = 0; }
  Py_XDECREF(r);
  return y;
}

void fir8_block(void* h, const svOpenArrayHandle x, const svOpenArrayHandle y, int n) {
  if (n < 0 || n > svSize(x, 1) || n > svSize(y, 1)) {
    fprintf(stderr, "fir8_block: n=%d but size(x)=%d size(y)=%d\n", n, svSize(x, 1), svSize(y, 1));
    abort();
  }
  if (!h) return;
  PyObject* mx = PyMemoryView_FromMemory((char*)svGetArrayPtr(x), 2 * n, PyBUF_READ);
  PyObject* my = PyMemoryView_FromMemory((char*)svGetArrayPtr(y), 2 * n, PyBUF_WRITE);   /* Python writes y in place */
  PyObject* r = PyObject_CallMethod((PyObject*)h, "block", "OO", mx, my);
  if (!r) fail("Fir8.block");
  Py_XDECREF(r);
  release(mx, "Fir8.block x");
  release(my, "Fir8.block y");
}

/* ================= Python-only extras (py_extra_pkg.sv) ======================================= */

/* ---- wide integers: svBitVecVal words (32-bit, LSW first) <-> Python int --------------------- */
static PyObject* bits_to_py(const svBitVecVal* v, int nbits) {
  svBitVecVal w[16];                                        /* up to 512 bits in this lab */
  int nw = (nbits + 31) / 32;
  memcpy(w, v, 4 * nw);
  if (nbits % 32) w[nw - 1] &= (1u << (nbits % 32)) - 1;    /* unused top bits are not guaranteed 0 */
  /* little-endian words of a little-endian host = one little-endian byte string (x86/ARM) */
  return PyLong_FromUnsignedNativeBytes(w, 4 * nw, Py_ASNATIVEBYTES_LITTLE_ENDIAN | Py_ASNATIVEBYTES_UNSIGNED_BUFFER);
}

static int py_to_bits(PyObject* o, svBitVecVal* v, int nbits) {
  int nw = (nbits + 31) / 32;
  Py_ssize_t need = PyLong_AsNativeBytes(o, v, 4 * nw, Py_ASNATIVEBYTES_LITTLE_ENDIAN |
                                         Py_ASNATIVEBYTES_UNSIGNED_BUFFER | Py_ASNATIVEBYTES_REJECT_NEGATIVE);
  if (need < 0) return 0;                                   /* not an int, or negative */
  svBitVecVal top = nbits % 32 ? ~((1u << (nbits % 32)) - 1) : 0;
  if (need > 4 * nw || (v[nw - 1] & top)) {
    PyErr_Format(PyExc_OverflowError, "result does not fit in %d bits", nbits);
    return 0;
  }
  return 1;
}

void py_mul_wide(const svBitVecVal* a, const svBitVecVal* b, svBitVecVal* p) {
  PyObject* f = callable("golden", "mul_wide");
  memset(p, 0, 4 * 7);
  if (!f) return;
  PyObject* pa = bits_to_py(a, 100);
  PyObject* pb = bits_to_py(b, 100);
  PyObject* r = (pa && pb) ? PyObject_CallFunctionObjArgs(f, pa, pb, NULL) : NULL;
  if (!r || !py_to_bits(r, p, 200)) fail("mul_wide");
  Py_XDECREF(r); Py_XDECREF(pa); Py_XDECREF(pb);
}

/* ---- generic bridge: any module.func(int64...) -> int64, no C change per function ---------- */
long long py_call_i64(const char* mod, const char* func, const svOpenArrayHandle args) {
  PyObject* f = callable(mod, func);
  if (!f) return 0;
  int n = svSize(args, 1);
  const long long* a = (const long long*)svGetArrayPtr(args);
  PyObject* t = PyTuple_New(n);
  for (int i = 0; i < n; i++) PyTuple_SET_ITEM(t, i, PyLong_FromLongLong(a[i]));   /* steals the ref */
  PyObject* r = PyObject_Call(f, t, NULL);
  Py_DECREF(t);
  long long v = r ? PyLong_AsLongLong(r) : 0;
  if (!r || PyErr_Occurred()) { fail(func); v = 0; }
  Py_XDECREF(r);
  return v;
}

/* ---- control ------------------------------------------------------------------------------- */
void py_set_bug(const char* name) {                         /* runtime twin of GOLDEN_BUG=<name> */
  PyObject* f = callable("golden", "set_bug");
  PyObject* r = f ? PyObject_CallFunction(f, "s", name) : NULL;
  if (f && !r) fail("set_bug");
  Py_XDECREF(r);
}

const char* py_last_error(void) {                           /* returned string must outlive the call */
  static char out[sizeof err];
  memcpy(out, err, sizeof err);
  err[0] = 0;
  return out;
}

#ifdef __cplusplus
}
#endif
