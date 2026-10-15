# Verilator DPI notes (measured, Verilator 5.052, macOS)

Append-only. One `## NN_name` section per step.

## 01_first_call
- `.c` files on the `verilator` command line are compiled with `$(CXX)` (clang warns "treating 'c' input as 'c++'" on a cache miss). Every imported function needs C linkage: `extern "C"` or `#include "V<top>__Dpi.h"` before the definitions.
- `V<top>__Dpi.h` (in the `-Mdir`) holds one `extern "C"` prototype per import. Including it turns a return-type mismatch into "functions that differ only in their return type cannot be overloaded". A *parameter* mismatch defined outside `extern "C"` silently becomes a C++ overload → link error `Undefined symbols "_negate"`.
- Missing / mangled / `static` symbol → macOS ld: `Undefined symbols for architecture x86_64: "_factorial", referenced from: ...Vdpiimwrap_top__DOT__factorial_TOP...`.
- Each import gets a generated wrapper `Vtop___024root____Vdpiimwrap_<scope>__DOT__<name>_TOP` that converts types and passes a temporary for each `output` (copied back after the call).
- `import "DPI"` (1800-2005 spelling): `%Error-UNSUPPORTED: Unsupported DPI type 'DPI': Use 'DPI-C'`.
- `import "DPI-C" \expect = function int fexpect();` works (c_name must be escaped when it is an SV keyword).
- `pure`: no call elimination observed (unused result, `f(2)+f(2)`, loop) — every call executes.
- Importing libc `strlen` directly fails: Verilator emits `unsigned long long strlen(const char*)` for `longint unsigned`, which clashes with `size_t strlen` from `<string.h>` (included by the generated code). No SV type maps to `unsigned long`; use a wrapper. libm `sin/pow/fabs/log10` and libc `access` import fine.
- Same C name imported with two different signatures in two packages: `Duplicate declaration of DPI function with different signature` (followed by an internal error).
- SV gotcha seen while writing labs: `$display(c ? "PASS" : "FAIL")` prints a number (the ternary yields an integral, not a string).

## 03_state_and_handles
- `.c` files passed to `verilator --binary` are compiled with the C++ compiler (clang: `treating 'c' input as 'c++' when in C++ mode, this behavior is deprecated`). DPI functions therefore need `extern "C"`, and C idioms invalid in C++ (implicit `void*` casts from `malloc`) fail.
- The generated `V<top>__Dpi.h` is in the Mdir and the C files compile with `-I.` from there, so `#include "Vtop__Dpi.h"` works with no extra flag. It declares `chandle` as `void*` and names parameters after the SV formals. Including it turns the book's `counter7(c7* inst, ...)` (Sample 12.9) into `error: conflicting types for 'counter7'`; without it the mismatch links silently (C linkage has no parameter types).
- Missing `extern "C"` on C++ wrappers: link fails with `"_counter7_new", referenced from: ... ld: symbol(s) not found` (macOS adds the leading `_`).
- Internally Verilator passes `chandle` as a 64-bit `QData` (`unsigned long long`) in its `Vdpiimwrap_*` wrappers.
- Two always blocks that call the same import in the same time step: Verilator 5.052 called the second-declared instance first (u2 before u1). `final` blocks: `top`'s ran before the instances' (u2, then u1). Both orders are unspecified by the LRM.
- A `pure` import with hidden state (a call counter): Verilator 5.052 still executed all 13 calls (a merged duplicate, a discarded `void'()` result, and a loop whose results are overwritten). The LRM allows eliminating them; do not rely on either behavior.
- `--threads 2`: with the default `--threads-dpi pure`, pure imports were called from 2 OS threads and non-pure imports from 1. `--threads-dpi none` serializes them to 1 thread. `--threads-dpi all` gave the same counts as `pure` in this design (non-pure calls stayed on 1 thread). Results were identical in every mode.
- `chandle` rules (IEEE 1800-2023 6.14) under `verilator --lint-only -Wall`: `int x = h` only warns (WIDTHTRUNC, 64→32 bits); `h + 1`, `assign g = h` and `@(h)` are accepted silently; only `chandle` inside a packed struct is an error. Verilator models chandle as a 64-bit integer, so code that relies on this will not port to commercial simulators.
- `import "DPI-C" function void bump(ref int x);` is accepted silently (no warning even with `-Wall`) and mapped to `void bump(int* x)`. IEEE 1800 forbids `ref` in imports; commercial tools reject it.
- Imports in `always_comb`/`assign`: exactly one call per input change per call site (2 sites, 10 changes → 2 + 20 calls). Event-driven simulators may evaluate more often; keep stateful models out of combinational code.
- Including `Vtop__Dpi.h` rescues C++ wrappers written without `extern "C"`: the header's earlier `extern "C"` declarations give the later definitions C linkage (lab `nocxxh` build links and runs correctly).

## 02_data_types
- `shortreal` in a DPI signature: Verilator warns `SHORTREAL` and generates `double` in `Vtop__Dpi.h` (LRM: `float`). A C definition with `float` links silently and reads garbage (0.1 → -1.59e-23). Including `Vtop__Dpi.h` turns it into a compile error.
- `ref` in an import is accepted silently (generates `int*`); the LRM forbids it.
- A `1'bz` literal as a DPI argument: `%Error-UNSUPPORTED: Unsupported tristate construct: ARG`. X/Z held in variables arrive as 0 (2-state); C-written `bval` bits are dropped on output.
- Output arguments are uninitialized stack locals in the generated wrapper (`svBitVecVal v__Vcvt[2];`) and are copied back unconditionally: an output C never writes overwrites the SV variable with stale stack data (measured: the previous call's 40-bit temp).
- Copy-back masks to the declared width (`VL_SET_Q_SVBV(40, ...)`, scalars `1U & x`); input chunks arrive with zero unused bits and no sign extension. The LRM guarantees neither.
- `SV_GET_SIGNED_BITS(v, N)` in `vltstd/svdpi.h` (Annex I text) tests bit N instead of N-1: `SV_GET_SIGNED_BITS(0x80, 8)` = 128.
- Result types: `bit [31:0]` → `svBitVecVal`; `bit [32:0]` and any 4-state vector (`logic [6:0]`, `integer`, `time`) are errors citing IEEE 1800-2023 35.5.5.
- Verilator skips verilation (and its warnings) when the `-Mdir` is up to date: a check that greps warnings needs a clean build.
- SV gotcha seen in testbenches: `$display(c ? "PASS" : "FAIL")` prints a number (the string literal is integral in an expression).

## 08_python_golden_model
- Open-array actuals must be fixed-size unpacked arrays: a dynamic array (or queue) is rejected
  (`Unsupported: DPI argument of type DYNARRAYDTYPE`, or an internal error `Passing dynamic array or queue
  as actual argument to DPI open array is not yet supported` depending on where it is declared).
- An assignment pattern `'{...}` as an open-array actual: `Unsupported: Assignment pattern applies against
  non-struct/union data type: 'UNSIZEDARRAYDTYPE'`. Assign it to a fixed array variable first.
- `svGetArrayPtr()` of an *input* fixed array points at the SV variable itself (writes in SV after the call
  are visible through a pointer kept by C/Python). An *output* open array is a temporary on the C stack
  (different address on every call), copied back after the call returns.
- Unpacked-array argument shape must match exactly: `logic signed [15:0] c[8]` -> `input shortint x[8]` is
  `%Error-UNSUPPORTED: Shape of the argument does not match the shape of the parameter`. Same family: a
  `shortint` array on a `logic signed [15:0]` array port is `Array element types are not equivalent`.
- `$error` stops the simulation (`Verilog $stop`, exit code 1) unless `+verilator+error+limit+N`.
- `$display(cond ? "PASS" : "FAIL")` prints a number, not the string (the argument is not a format literal).
- A comment that starts with `// Verilator:` is parsed as a pragma (`Unknown verilator comment`).
- Variable with initializer declared inside a loop body of an `initial` block is static: the initializer
  runs once at time 0 (`int len = $urandom_range(...)` was always 0). Use `automatic`. No warning.
- Verilator compiles `.c` files as C++ (clang warns `treating 'c' input as 'c++'`); `#include "Vtop__Dpi.h"`
  works because `--top-module top` makes the prefix `Vtop`.

## 06_golden_model_c
- **Open arrays only take fixed-size actuals.** Passing a dynamic array (or queue) to an `input T a[]`
  DPI formal fails at elaboration: `%Error-UNSUPPORTED: Unsupported: DPI argument of type DYNARRAYDTYPE`
  (pointing at the import), followed by `Internal Error: ../V3Task.cpp:759`. Fixed-size unpacked arrays work
  (`svSize`, `svLow`, `svGetArrayPtr`, `svGetArrElemPtr1` all fine, also for `output`). Workaround: copy into a
  fixed buffer and pass the length as a separate `int` (see `golden_pkg.sv`).
- **`randomize()` runs an external SMT solver (z3)**: ~5-10 ms per call on this machine, CPU mostly idle
  (sim `cpu 0.68 s` vs `walltime 12.9 s` for 2500 calls). Parallel sims contend for it. It dwarfs DPI cost
  (a DPI call into C is ~2-10 ns); use `$urandom` stimulus when measuring anything else.
- **Sized negative literal in `dist`**: `x dist {-16'sh8000 := 5}` on a `shortint` is unsatisfiable
  (`%Warning-UNSATCONSTR`, `randomize()` returns 0). Plain `-32768` works.
- User `.c` files are compiled with the C++ compiler (`clang: warning: treating 'c' input as 'c++'`) from inside
  the `-Mdir`, so `#include "Vtop__Dpi.h"` works and gives C linkage + prototype checking for free.

## 04_arrays_structs_strings
- Open-array actuals: only fixed-size arrays. Dynamic array → `%Error-UNSUPPORTED: Unsupported: DPI argument of type DYNARRAYDTYPE`; queue → `... QUEUEDTYPE`; slice `a[1:2]` → `%Error: Internal: Unexpected Call`. Workaround: copy through a fixed buffer + explicit count.
- Unpacked struct as DPI argument → `Unsupported: DPI argument of type REFDTYPE '<name>'`. Use packed structs (svBitVecVal) or separate members.
- Packed open-array elements are stored natively: bit[7:0] = 1 byte, bit[12:0] = 2, bit[63:0] = 8, bit[99:0] = 16 (32-bit words). A `svBitVecVal*` cast on a `svGetArrElemPtr1` result is wrong for widths ≤ 32 (reads neighbors); use `svGetBitArrElem1VecVal`.
- Flat storage of unpacked arrays: low index first, row-major (`int v[10:1]` has v[1] at offset 0).
- `output` arrays: open-array temporary arrives zero-filled and is copied back whole (unwritten elements become 0); fixed-size output arrays return garbage in unwritten elements. `inout` keeps them.
- `svGetArrElemPtr*` out of range or with the wrong number of indices: run-time `%Warning: DPI svOpenArrayHandle function ...` and NULL.
- Returned strings are copied into std::string immediately (one static buffer survives two calls in one `$display`).
- 4-state: `bval` written by C is ignored; `svGetLogicArrElem*VecVal` writes `bval = 0`.
- C compiler warnings (e.g. `-Wreturn-stack-address`) only appear in the Verilator build log; with ccache they are replayed on cache hits.
- `buf` is a Verilog keyword (gate primitive): `int buf[256];` is a syntax error.

## 05_export_and_context
- Timing controls anywhere below an exported task (`#`, `@`, or nested in a called task) are a compile error:
  `%Error-UNSUPPORTED: ... Unsupported: Timing controls inside DPI-exported tasks`. Book Sample 12.40 does not build.
  Portable alternative: pull model (SV loops and waits, C is a zero-time iterator), see `05_export_and_context/lab/mem_pull.*`.
- Generated header declares exported tasks as `void` (LRM Annex H: `int` disable flag); imported tasks as `int`.
  `svIsDisabledState()` links and returns 0.
- Imported *function* calling an exported zero-time *task*: accepted (LRM: illegal).
- Non-context import calling an export: fatal only if no scope was ever set
  (`Testbench C called 'X' but scope wasn't set ... See IEEE 1800-2023 35.5.3.`, preceded by a
  `%Warning: DPI C Function called by Verilog DPI import with missing 'context' keyword.`);
  if an earlier context call left a scope, the export of THAT instance runs silently.
- `svGetScopeFromName` takes the `%m` name (`top.b2`, `top.gen[0].u`); `TOP.top.b2` and relative names return NULL.
- `svPutUserData`/`svGetUserData`, `svGetCallerInfo` (path as on the command line) work.
- `pure` is not exploited: discarded/duplicated/loop-invariant pure calls all execute (also with -O3).
  A DPI function in a continuous assign ran 11 times for 5 input changes.
- Cost per call (5 M calls, idle machine): generic ≈ pure ≈ 1.3–1.8 ns, context ≈ 10 ns, context + 1 export ≈ 18–21 ns.
- Unwritten `output` args come back as garbage: the import wrapper passes an uninitialized temp (`o__Vcvt`).
- `$error` defaults to `$stop` (abort) at the first error; `+verilator+error+limit+N` keeps going.

## 07_embedding_python
- `.c` files passed to `verilator --binary` are compiled with the C++ compiler (`__cplusplus=201703`; clang warns "treating 'c' input as 'c++'"). Include `Vtop__Dpi.h` so definitions get `extern "C"` from the prototypes.
- Open-array formal (`input byte unsigned d[]`) with a **dynamic array** actual: `%Error-UNSUPPORTED: Unsupported: DPI argument of type DYNARRAYDTYPE` (+ an internal error in V3Task). A fixed-size actual works.
- A `//` comment whose first word is `Verilator:` (any case) is parsed as a pragma: `%Error-BADVLTPRAGMA: Unknown verilator comment`. Don't start comments with the tool's name.
- `$finish` does not stop the calling process: statements after it in the same `initial` still execute, then `final` blocks run.
- `$error` with the default error limit becomes `$stop`: "Aborting...", exit status 1, **`final` blocks do not run**. `+verilator+error+limit+N` keeps going ("$stop, ignored due to +verilator+error+limit").
- `--threads 4` with the default `--threads-dpi pure`: non-pure DPI calls are serialized onto ONE thread that is NOT the thread that ran `initial` (3200/3200 calls off the init thread). `pure` imports or `--threads-dpi all` spread calls over 4 threads. Any thread-affine C library (CPython) needs per-call thread attach (`PyGILState_Ensure`).
- Embedded CPython 3.14: `python3-config --ldflags` lacks `-lpython3.14` (use `--embed`); numpy imports fine in the Verilator binary (~0.1 s) but only once per process (re-init + import → "cannot load module more than once per process").
- macOS: `WEXITSTATUS(system(cmd))` does not compile as C++ ("cannot take the address of an rvalue"); `<wait.h>` (Spear Sample 12.52) is Linux-only, use `<sys/wait.h>`.
- Unpacked array port connections with non-equivalent element types are checked inconsistently: a whole
  `shortint c[8]` on a `logic signed [15:0] coef [8]` port fails (`Array element types are not equivalent`),
  but a sub-array `shortint c[2][8]` -> `.coef(c[u])` builds and simulates. Both are illegal per the LRM.
- Calling any CPython API (e.g. `PyLong_FromNativeBytes`) before the interpreter is initialized segfaults the
  simulator on the first DPI call: make every bridge entry point go through the function that initializes.

## 08_python_golden_model (contract unification)
- Step 08 now links step 06's `golden_pkg.sv` by relative path; Python-only extras live in `py_extra_pkg.sv`. One build line per backend, no SV change.
- 06's `golden.c` and `wall.c` rely on `#include "Vtop__Dpi.h"` for C linkage (no `extern "C"` of their own). A testbench that links `wall.c` without importing `wall_s` still builds: the definition just gets C++ linkage and is unused.
- A contract with no shutdown call: the bridge registers `atexit(Py_FinalizeEx wrapper)` on first init. Verilator's `main()` returns after `final` blocks, so Python's buffered stdout is flushed and `Fir8.__del__` runs.
- Bug selection without SV or rebuild: `GOLDEN_BUG=fir_trunc vlr ...` (bash passes a prefix assignment to a function's child processes); the C twin is `-CFLAGS -DMUTANT=1` (rebuild).
