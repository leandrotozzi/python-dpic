/* Step 07, experiment "config": the two configuration APIs. */
#include <Python.h>
#include "Vtop__Dpi.h"
#include <stdio.h>
#include <time.h>

static int with_config(const char *venv, int replace_path) {
  PyConfig cfg;
  PyConfig_InitPythonConfig(&cfg);                 /* like `python3`; Isolated = like `python3 -I` */
  PyStatus st = PyConfig_SetBytesString(&cfg, &cfg.program_name, "dpi-sim");
  if (*venv && !PyStatus_Exception(st))            /* a venv is found from the executable path */
    st = PyConfig_SetBytesString(&cfg, &cfg.executable, venv);
  if (replace_path && !PyStatus_Exception(st)) {   /* pitfall: this REPLACES the computed path */
    cfg.module_search_paths_set = 1;
    st = PyWideStringList_Append(&cfg.module_search_paths, L"py");
  }
  cfg.buffered_stdio = 0;
  if (!PyStatus_Exception(st)) st = Py_InitializeFromConfig(&cfg);
  PyConfig_Clear(&cfg);
  if (PyStatus_Exception(st)) {
    printf("LOG init_error func=%s msg=\"%s\"\n", st.func ? st.func : "-", st.err_msg ? st.err_msg : "-");
    return -1;
  }
  return 0;
}

static int with_initconfig(const char *venv) {      /* PEP 741, new in 3.14: no struct layout */
  PyInitConfig *c = PyInitConfig_Create();
  int bad = PyInitConfig_SetStr(c, "program_name", "dpi-sim")
         || PyInitConfig_SetInt(c, "buffered_stdio", 0)
         || (*venv && PyInitConfig_SetStr(c, "executable", venv))
         || Py_InitializeFromInitConfig(c);
  if (bad) {
    const char *msg = NULL;
    PyInitConfig_GetError(c, &msg);
    printf("LOG init_error msg=\"%s\"\n", msg ? msg : "-");
  }
  PyInitConfig_Free(c);
  return bad ? -1 : 0;
}

int cfg_init(const char *api, const char *venv, int replace_path) {
  int rc = api[0] == 'i' ? with_initconfig(venv) : with_config(venv, replace_path);
  fflush(stdout);
  return rc;
}

void cfg_report(void) {
  struct timespec t0, t1;
  PyRun_SimpleString(
      "import sys\n"
      "print(f'LOG cfg executable={sys.executable} venv={int(sys.prefix != sys.base_prefix)} '\n"
      "      f'unbuffered={int(not sys.stdout.line_buffering and sys.stdout.write_through)}')\n");
  clock_gettime(CLOCK_MONOTONIC, &t0);
  PyObject *np = PyImport_ImportModule("numpy");
  clock_gettime(CLOCK_MONOTONIC, &t1);
  if (np) {
    printf("LOG numpy ok=1 ms=%.0f\n", (t1.tv_sec - t0.tv_sec) * 1e3 + (t1.tv_nsec - t0.tv_nsec) / 1e6);
    fflush(stdout);                                /* C text first, then Python's */
    PyRun_SimpleString("import numpy as np; print('LOG numpy dot=%d' % int(np.arange(4) @ np.arange(4)))");
    Py_DECREF(np);
  } else {
    PyObject *exc = PyErr_GetRaisedException();
    printf("LOG numpy ok=0 exc=%s\n", Py_TYPE(exc)->tp_name);
    Py_DECREF(exc);
  }
  fflush(stdout);
}

void cfg_fin(void) { if (Py_IsInitialized()) Py_FinalizeEx(); }
