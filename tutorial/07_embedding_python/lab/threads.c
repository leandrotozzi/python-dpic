/* Step 07, experiment "threads". Build with -DGIL_SAFE for the correct pattern:
   release the GIL after init, take it around every call, take it back before finalize. */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <pthread.h>
#include <stdio.h>

static PyObject *f_add;
static PyThreadState *main_ts;          /* GIL_SAFE: the state saved by PyEval_SaveThread */
static pthread_mutex_t mu = PTHREAD_MUTEX_INITIALIZER;
static pthread_t seen[64];
static int n_seen, n_calls, n_on_init_thread;
static pthread_t init_thread;      /* the thread that ran Py_Initialize */

void th_init(void) {
  init_thread = pthread_self();
  Py_Initialize();
  PyObject *path = PySys_GetObject("path"), *dir = PyUnicode_FromString("py");
  PyList_Insert(path, 0, dir);
  Py_DECREF(dir);
  PyObject *m = PyImport_ImportModule("toys");
  f_add = PyObject_GetAttrString(m, "add");
  Py_DECREF(m);
#ifdef GIL_SAFE
  main_ts = PyEval_SaveThread();        /* this thread stops holding the GIL */
#endif
}

static void record(void) {
  pthread_mutex_lock(&mu);
  n_calls++;
  n_on_init_thread += pthread_equal(init_thread, pthread_self()) != 0;
  int i = 0;
  while (i < n_seen && !pthread_equal(seen[i], pthread_self())) i++;
  if (i == n_seen && n_seen < 64) seen[n_seen++] = pthread_self();
  pthread_mutex_unlock(&mu);
}

int th_call(int x) {
  record();
#ifdef GIL_SAFE
  PyGILState_STATE g = PyGILState_Ensure();
#endif
  PyObject *r = PyObject_CallFunction(f_add, "ii", x, 1);
  int v = r ? (int)PyLong_AsLong(r) : -1;
  Py_XDECREF(r);
#ifdef GIL_SAFE
  PyGILState_Release(g);
#endif
  return v & 0xffff;
}

void th_fin(void) {
#ifdef GIL_SAFE
  PyEval_RestoreThread(main_ts);
#endif
  Py_CLEAR(f_add);
  Py_FinalizeEx();
  printf("LOG threads calls=%d distinct_threads=%d on_init_thread=%d\n", n_calls, n_seen, n_on_init_thread);
}
