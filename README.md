# python-dpic

[![labs](https://github.com/leandrotozzi/python-dpic/actions/workflows/labs.yml/badge.svg)](https://github.com/leandrotozzi/python-dpic/actions/workflows/labs.yml)

**DPI-C from scratch, then Python as a golden model.** An incremental, hands-on tutorial on the
SystemVerilog Direct Programming Interface, measured on Verilator 5.052, ending with Python
functions called as bit-exact reference models from a SystemVerilog testbench.

### → Read it at **<https://leandrotozzi.github.io/python-dpic/>**

The site is the tutorial's home: syllabus, setup, the eight guides, the Verilator gaps page and the
references all live there. Offline, open [`tutorial/index.html`](tutorial/index.html) from a clone.

## Quick start

Needs Verilator 5.x, a C/C++ compiler, Python 3.14, z3 (step 06) and numpy (step 08).

```sh
git clone https://github.com/leandrotozzi/python-dpic.git
cd python-dpic/tutorial/01_first_call/lab
python3 check.py        # builds, runs, asserts every claim of guide 01
```

## Repository layout

| Path | What |
|---|---|
| [`tutorial/`](tutorial) | The tutorial: one `NN_*/guide.html` + `NN_*/lab/` per step, shared DUTs in `common/rtl`, raw measurements in `NOTES.md` |
| [`legacy/`](legacy) | Earlier experiments the tutorial grew out of (2014 onward, irun / Python 2); not maintained, links to the third-party sources they used |

The labs run on every push in CI (macOS, Verilator 5.052, Python 3.14).

## License

[MIT](LICENSE). Bundled fonts, KaTeX and highlight.js keep their own licenses (listed in `LICENSE`).
