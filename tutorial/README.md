# DPI-C from scratch, then Python as a golden model

An incremental, hands-on tutorial. **Part A** builds a solid understanding of the SystemVerilog
Direct Programming Interface (DPI-C). **Part B** uses that foundation to embed a Python
interpreter and call Python functions as golden (reference) models from a SystemVerilog testbench.

Every step has a guide (`NN_*/guide.html`, open it in a browser, works offline) and a lab
(`NN_*/lab/`) that runs on Verilator and validates every claim the guide makes:

```sh
cd tutorial/01_first_call/lab && python3 check.py     # builds, runs, asserts
```

Each guide follows the same layout: tutorial text → worked examples → exercises with hidden
solutions → self-grading quiz → lab walkthrough → cheat sheet.

## Syllabus

| # | Step | You learn | Book (Spear & Tumbush 3rd ed., ch. 12) |
|---|---|---|---|
| **Part A — DPI-C** |||||
| 01 | [`01_first_call`](01_first_call/guide.html) | What DPI is (and is not: PLI/VPI), `import "DPI-C"`, `pure`, renaming (`c_name =`), calling libc/libm directly, how Verilator compiles and links C/C++, the generated `V<top>__Dpi.h` prototype header, `extern "C"` and name mangling, what happens on a signature mismatch | §12.1 |
| 02 | [`02_data_types`](02_data_types/guide.html) | The type mapping table (`byte`…`longint`, `real`, `chandle`, `string`, `bit`/`logic` scalars and vectors), `svBitVecVal`/`svLogicVecVal` canonical representation (`aval`/`bval`), wide vectors (> 64 bits), signedness, argument directions (`input`/`output`/`inout`) and who owns memory, 2-state vs 4-state (Verilator is 2-state) | §12.1.3–12.1.4, §12.2.3–12.2.5 |
| 03 | [`03_state_and_handles`](03_state_and_handles/guide.html) | Static C state vs per-instance state, `chandle`, constructor/destroy pairs, C++ classes behind a C ABI (static wrappers), transaction-level C++ models, leaks and lifetime | §12.2.1–12.2.2, §12.3 |
| 04 | [`04_arrays_structs_strings`](04_arrays_structs_strings/guide.html) | Fixed-size arrays, open arrays (`[]`, `svOpenArrayHandle`, `svLow/svHigh/svSize/svGetArrElemPtr`), packed open arrays, structs across the boundary (layout rules), strings in and out (who frees what) | §12.4–12.6 |
| 05 | [`05_export_and_context`](05_export_and_context/guide.html) | `export "DPI-C"` functions and tasks, `context` vs `pure`, scopes (`svGetScope`, `svSetScope`, `svGetNameFromScope`), calling back into SV from C, time-consuming exported tasks, a C-driven command-file memory model, the rules that keep the simulator's optimizer honest | §12.7–12.8 |
| 06 | [`06_golden_model_c`](06_golden_model_c/guide.html) | The golden-model pattern end to end: DUT ([`common/rtl`](common/rtl)) + C reference model + SV scoreboard, random stimulus, bit-exact comparison, bug injection, where to put the comparison (per-transaction vs per-batch), cost per DPI call | §12.4 (Fibonacci), ch. 1 layered TB |
| **Part B — Python** |||||
| 07 | [`07_embedding_python`](07_embedding_python/guide.html) | The CPython C API for embedders: lifecycle (`Py_Initialize*` once, finalize in `final`), `sys.path`, import and call, reference counting, error propagation to `$error`, venvs via `PyConfig`, building/linking with `python3-config --embed`, the GIL (and why the simulator thread holds it) | §12.9 (Perl wrapper idea) |
| 08 | [`08_python_golden_model`](08_python_golden_model/guide.html) | Python as the golden model of step 06's DUTs: `zlib.crc32` and a numpy FIR; converting ints of any width, arrays via buffers/numpy, batching to amortize call overhead, measured calls/s (C vs Python), a generic `py_call` bridge, when to graduate to pysv / PyHDL-IF / cocotb | — |

Shared DUTs (used from step 06 on): [`common/rtl/crc32_stream.sv`](common/rtl/crc32_stream.sv)
(CRC-32/IEEE, bit-exact with `zlib.crc32`) and [`common/rtl/fir8.sv`](common/rtl/fir8.sv)
(8-tap Q1.15 FIR, round half-up, saturating).

## Toolchain

Measured on macOS x86_64: **Verilator 5.052** (the only DPI-capable simulator here; Icarus has no DPI),
**Python 3.14** with numpy, clang. Commercial simulators (Questa, VCS, Xcelium) follow the same
IEEE 1800 Annex H rules; where they differ from Verilator the guides say so.

## References

- **IEEE Std 1800-2023**, clause 35 (DPI), Annex H (DPI C layer), Annex I (`svdpi.h`). The normative source.
- **Spear & Tumbush**, *SystemVerilog for Verification*, 3rd ed., Springer 2012, ch. 12 "Interfacing with C/C++".
- **Verilator manual**, "Direct Programming Interface (DPI)" and "Connecting to C++": <https://verilator.org/guide/latest/connecting.html>
- Doulos, *SystemVerilog DPI tutorial*: <https://www.doulos.com/knowhow/systemverilog/systemverilog-tutorials/systemverilog-dpi-tutorial/>
- AMD UG900, "Open Arrays in DPI" / "Support for svdpi.h functions" (a clear vendor summary of Annex H/I).
- AMIQ, *How to Connect SystemVerilog with Python* (2019) — copy in [`../amiq`](../amiq).
- Python docs, *Embedding Python in Another Application* and *Python Initialization Configuration* (PEP 587 / PEP 741).
- M. Ballance, *Properly Introducing Python to your UVM Testbench*, DVCon US 2026 (PyHDL-IF).
- Libraries for later: [pysv](https://github.com/Kuree/pysv), [PyHDL-IF](https://github.com/fvutils/pyhdl-if), [cocotb](https://www.cocotb.org), [pyuvm](https://github.com/pyuvm/pyuvm).
