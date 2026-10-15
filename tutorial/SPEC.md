# Authoring spec for the tutorial steps

Rules every step (`tutorial/NN_*/`) follows. Read `README.md` (syllabus) first.

## Language and audience
- **Everything in English**: code, comments, guide, logs, markdown.
- Reader: senior digital IC designer (ASIC/FPGA/DSP), fluent in SV RTL and C, new to DPI internals.
  No hand-holding on SV or C syntax; full depth on the boundary between them.
- Incremental: each step may only assume earlier steps. Link back (`../NN_x/guide.html#anchor`) instead of repeating.

## Files
```
NN_name/
  guide.html          the tutorial page (single file, offline)
  lab/
    run.sh            builds + runs everything; sources ../../common/lab.sh (vlb/vlr/py_flags)
    check.py          runs run.sh (unless --no-run) and asserts EVERY number/behavior the guide states
    *.sv *.c *.cpp *.py   one self-checking testbench per experiment, top module named `top`
    ex/               exercise solutions (also built and checked by run.sh/check.py)
    build/            outputs, git-ignored
```
- Testbenches print `LOG <tag> k=v ...` lines and `PASS`/`FAIL`; check.py parses them (see the `kv()` helper
  pattern in `../dd_work/study/spear_sv/lab/oop/check.py`).
- Experiments that are *expected* to fail (signature mismatch, missing `context`, wrong `extern "C"`) are
  run too, and check.py asserts the exact error text/behavior. That is how the guide's pitfalls are proven.
- `cd NN_name/lab && python3 check.py` must pass in < 3 min. Parallelize Verilator builds (`vlb ... &` + `wait`);
  never `pkill`/`killall`.
- Python labs: use `python3` on PATH (3.14, numpy available). Prefer the stable/limited C API where it costs nothing.

## guide.html
Skeleton, CSS and JS: copy the `<head>`, theme toggle and TOC script from
`../dd_work/study/spear_sv/ch04_if/guia.html` (Spanish; translate any visible text), with paths changed to
`../assets/guide.css`, `../assets/katex/...`, plus `<link rel="stylesheet" href="../assets/quiz.css">` and
`<script defer src="../assets/quiz.js"></script>`. Diagram SVG conventions: `../dd_work/study/assets/DIAGRAMAS.md`
(Spanish reference; the CSS classes are the same in `../assets/guide.css`). Callout labels in CSS are already English
(`Key idea`, `Pitfall`, `Note`, `Book erratum`); custom labels via `style="--c-label:'In Verilator'"` etc.

Sections, in order:
0. **Tutorial** (the main part, 4000–7000 words). Teach in this order for each concept: problem it solves → exact
   semantics (what IEEE 1800-2023 clause 35 / Annex H says) → minimal complete code (SV side + C side, both
   compile and run in the lab) → actual output pasted from the lab → pitfall → "In Verilator" vs "Commercial
   simulators" when they differ. Code blocks ≤ ~25 lines, commented. Escape `<>&`. No raw `$` outside
   `<code>`/`<pre>` (KaTeX).
   - **≥ 6 inline SVG diagrams** (e.g. SV/C call stack across the boundary, memory layout of `svBitVecVal` words,
     `aval/bval` encoding, chandle → C heap object, open-array handle → descriptor → data, scope tree for
     export/context, the build/link pipeline, time line of a scoreboard comparison). Responsive (`viewBox`,
     `width:100%`), light/dark via CSS variables, readable text.
   - Map to the book: cite "Sample 12.N", "§12.x" with corrections where the book is wrong or dated
     (book is 2012/IEEE 1800-2009, uses VCS/`io_printf`/`veriuser.h`). OCR text: `../dd_work/study/spear_sv/text/ch12.txt`
     (OCR confuses `_`↔space, `l/1`, `O/0`, `$`→`S`; check the PDF page when a character matters:
     `pdftoppm -f N -l N -r 150 -png "../dd_work/refs/SystemVerilog for Verification.pdf" <scratch>/p`, PDF page = book page + 36 in ch. 12).
1. **Learning objectives** (5–8 bullets) and prerequisites (link to earlier steps).
2. **Exercises** (10–12, graded ★/★★/★★★) with **full hidden solutions** (`<details><summary>Show solution</summary><div class="a">…</div></details>`).
   Mix: write code for a spec; find the bug (in SV, C, or the build line); predict the output; at least 2 of
   the book's ch. 12 exercises (cite "Ex. 12.N") where they fit the step. Every code solution lives in `lab/ex/`
   and passes check.py.
3. **Quiz** (12–15 self-grading multiple-choice questions, `.quiz` markup documented at the top of
   `../assets/quiz.js`, with a `<p class="quiz-score">`). Each has a `.why` explaining the right *and* the tempting
   wrong answer. Reasoning questions, not trivia ("what does C see in `*out` if…", "which call needs `context`").
4. **Lab walkthrough**: what to predict before running, how to run, what to look at, a results table with the real numbers.
5. **Cheat sheet**: one dense table (construct → SV declaration → C prototype → pitfall) + 5–10 key rules.

Top bar: link `← Tutorial index` to `../index.html`, previous/next step links.

## Verification before you finish
- `python3 check.py` passes.
- Render with Playwright (`python3`; light and dark; 1360 px and 390 px wide): 0 KaTeX errors, no raw `$`,
  no horizontal page scroll (wide `<pre>` scroll inside themselves), look at the screenshots of every SVG and
  fix overlaps. Save screenshots under the scratchpad, not the repo.
- New tool behaviors discovered (Verilator DPI quirks): append to `tutorial/NOTES.md` under a `## NN_name`
  heading (append only, `cat >>`).
