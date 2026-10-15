#!/usr/bin/env python3
"""Asserts every number and behavior that 07_embedding_python/guide.html states.
Usage: cd lab && python3 check.py            (runs run.sh first, ~1 min with ccache)
       python3 check.py --no-run             (only parses build/)
"""
import pathlib
import re
import subprocess
import sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["./run.sh"], cwd=H, check=True, capture_output=True)


def log(name):
    return (B / f"{name}.log").read_text()


def kv(text, tag):
    """'LOG <tag> a=1 b=x' -> {'a': '1', 'b': 'x'} (first matching line)."""
    m = re.search(rf"^LOG {tag} (.*)$", text, re.M)
    assert m, f"missing 'LOG {tag}'"
    return dict(re.findall(r'(\S+?)=("[^"]*"|\S+)', m[1]))


def lines(text):
    """Simulation output without Verilator's '- ' report lines."""
    return [l for l in text.splitlines() if not l.startswith("- ")]


n_ok = 0


def ok(cond, msg):
    global n_ok
    assert cond, msg
    n_ok += 1


# 1) basic: conversions and their traps
b = log("basic")
ok("LOG who python 3.14" in b, "embedded interpreter is the system 3.14")
ok(kv(b, "add") == {"r": "42"}, "add")
ok(kv(b, "wrap") == {"r": "-2147483648"}, "(int) cast of PyLong_AsLong silently wraps 2**31")
ok(kv(b, "checked") == {"rc": "1"}, "checked add reports overflow")
ok(kv(b, "checked2") == {"rc": "0", "sum": "-2"}, "checked add, normal case")
ok(kv(b, "hypot") == {"r": "5.000000"}, "PyFloat round trip")
ok("LOG reverse r=skcor C-IPD" in b, "string in/out")
ok(kv(b, "checksum") == {"r": "274"}, "bytes from an open array: 1+2+255+16")
ok(kv(b, "pow2") == {"p62": "4611686018427387904", "p63": "-1", "p64": "-1"}, "PyLong_AsLongLong overflow -> -1")
ok("LOG pow2_overflow n=63" in b and "LOG pow2_overflow n=64" in b, "OverflowError detected for 2**63 and 2**64")
ok(b.index("LOG fin rc=0 initialized=0") < b.index("LOG final done"), "Py_FinalizeEx from the final block")
ok(kv(b, "lang")["compiled_as"] == "c++", "Verilator compiles .c as C++")

# 2) build: --embed matters
ne = (B / "noembed.build").read_text()
ok("Undefined symbols" in ne and "_Py_Initialize" in ne and "BUILD_FAIL" in ne, "no -lpython3.14 without --embed")
ok("-lpython" not in subprocess.run(["python3-config", "--ldflags"], capture_output=True, text=True).stdout,
   "python3-config --ldflags omits libpython")

# 3) lifecycle
L = {m: lines(log(f"life_{m}")) for m in ("fin", "nofin", "guard", "raw", "cycle")}
ok(L["fin"] == ["SV mode=fin", "SV after say", "PY hello from python", "PY atexit handler ran",
                "LOG fin rc=0", "SV final block done"], "finalize flushes Python output and runs atexit")
ok(L["nofin"] == ["SV mode=nofin", "SV after say", "SV final block done"], "never finalized: Python output lost")
ok("LOG guard rc=-1" in L["guard"] and "LOG guard refused: interpreter not initialized" in L["guard"], "guard")
ok(L["raw"][-1] == "RUN_RC=139", "stale object after finalize: SIGSEGV")
cyc = log("life_cycle")
ok(kv(cyc, r"cycle numpy=0") == {"ok": "20", "of": "20"}, "20 init/finalize cycles with json work")
ok(kv(cyc, r"cycle numpy=1") == {"ok": "1", "of": "3"}, "numpy imports once per process")
ok("ImportError: cannot load module more than once per process" in cyc, "numpy re-import error text")
plain_ms = float(re.search(r"plain_ms=([\d.]+)", cyc)[1])
ok(5 < plain_ms < 1000, f"init+finalize costs tens of ms on an idle machine ({plain_ms})")
ok("LOG after_finish still running" in cyc, "Verilator: statements after $finish still execute")

# 4) stdout buffering, stdout redirected to a file
order = {m: [l for l in lines(log(f"buf_{m}"))] for m in ("none", "py", "both", "unbuf")}
ok(order["none"] == ["SV 0", "SV 1", "SV 2", "PY 0", "PY 1", "PY 2"], "no flush: Python text at finalize")
ok(order["py"] == ["PY 0", "PY 1", "PY 2", "SV 0", "SV 1", "SV 2"], "Python flush only: C text last")
inter = ["SV 0", "PY 0", "SV 1", "PY 1", "SV 2", "PY 2"]
ok(order["both"] == inter and order["unbuf"] == inter, "flush both sides (or buffered_stdio=0 + fflush)")

# 5) errors and reference counting
e = log("errors")
ok(kv(e, "divide ok") == {"rc": "0", "q": "3"}, "divide ok")
ok("LOG sv_py_error n=1 where=divide" in e and "ZeroDivisionError: division by zero" in e, "traceback to SV")
ok("in _inner" in e and "~~^^~~" in e, "full traceback with 3.11+ position markers")
ok(kv(e, "divide zero") == {"rc": "-1"}, "rc -1 on exception")
ok(kv(e, "stale v=-1") == {"pending": "1"}, "PyLong_AsLong(str) leaves a TypeError pending")
ok(kv(e, "stale call_result=NULL") == {"pending_after": "SystemError"}, "next call fails with SystemError")
ok("returned a result with an exception set" in e, "SystemError message")
ok(kv(e, "leak") == {"none": "0"} and re.search(r"LOG leak leaky=2$", e, re.M), "leak: 2 blocks per call")
ok(kv(e, "immortal") == {"none": "3221225472", "small_int": "3221225472", "big_int": "1"}, "immortal objects")
ok(kv(e, "errors") == {"total": "1"}, "exactly one reported error")

# 6) configuration
c = {m: log(f"cfg_{m}") for m in ("sys", "venv", "init", "initvenv", "replace", "venv_sys")}
ok("vl_config/Vtop venv=0 unbuffered=1" in c["sys"], "default sys.executable is the simulator binary")
for m in ("sys", "init", "venv_sys"):
    ok("LOG numpy ok=1" in c[m] and "LOG numpy dot=14" in c[m], f"numpy imports in the embedded interpreter ({m})")
    ok(int(re.search(r"numpy ok=1 ms=(\d+)", c[m])[1]) < 1000, "numpy import < 1 s")
for m in ("venv", "initvenv"):
    ok("build/venv/bin/python venv=1" in c[m] and "LOG numpy ok=0 exc=ModuleNotFoundError" in c[m],
       f"isolated venv selected via executable ({m})")
    ok("RuntimeWarning" not in c[m], "absolute venv path: no getpath warning")
ok("build/venv_sys/bin/python venv=1" in c["venv_sys"], "--system-site-packages venv")
ok('LOG init_error func=- msg="Failed to import encodings module"' in c["replace"], "module_search_paths_set pitfall")

# 7) threads
t = {n: log(n) for n in ("th_single", "th_np", "th_np_safe", "th_pure", "th_pure_safe", "th_all_safe")}
ok("calls=3200 distinct_threads=1 on_init_thread=3200" in t["th_single"], "single-threaded model: one thread")
ok(t["th_np"].strip().endswith("RUN_RC=139") and t["th_pure"].strip().endswith("RUN_RC=139"),
   "--threads 4 without GIL handling: SIGSEGV (pure and non-pure)")
ok("calls=3200 distinct_threads=1 on_init_thread=0" in t["th_np_safe"], "non-pure DPI: serialized on a worker thread")
for n in ("th_pure_safe", "th_all_safe"):
    ok("calls=3200 distinct_threads=4 on_init_thread=800" in t[n], f"{n}: 4 threads call DPI")
for n in ("th_single", "th_np_safe", "th_pure_safe", "th_all_safe"):
    ok("LOG lanes acc0=400 acc7=3200" in t[n], f"{n}: results identical")

# 8) exercise solutions
s = log("ex_shift")
ok(kv(s, "shift") == {"l4": "00000f10", "r4": "0800000f", "z": "800000f1", "l31": "80000000", "r40": "00000000"},
   "Ex. 12.1 in Python")
ok('LOG shift_error type=ValueError msg="negative shift count"' in s and "LOG naive r4=deadbeef" in s, "naive shift")
sh = log("ex_shifter")
ok("LOG sh a1=00000010 b1=0f000000" in sh, "shifter: ld=0 shifts the initial value")
ok("LOG sh a2=00000006 b2=00f00000" in sh, "shifter: ld=1 loads i<<n, ld=0 shifts the register")
ok("LOG sh calls=4 live=2" in sh and "LOG sh live_after_free=0" in sh, "class counter and chandle lifetime")
ev = log("ex_eval")
ok("LOG eval1 rc=0 r=1448.154688" in ev and "LOG eval2 rc=0 r=5050.0" in ev, "eval")
ok("python: ZeroDivisionError: division by zero" in ev and "Verilog $stop" in ev and "LOG eval3" not in ev,
   "$error stops Verilator at the first error by default")
ok(ev.strip().endswith("RUN_RC=1") and "LOG eval final ran" not in ev, "and the final block never runs")
el = log("ex_eval_limit")
ok("ignored due to +verilator+error+limit" in el and "LOG eval3 rc=-1" in el and "LOG eval4 rc=-1" in el, "limit")
ok("TypeError: must be real number, not str" in el and "LOG eval done" in el and "LOG eval final ran" in el, "eval4 TypeError, final runs")
ok(kv(log("ex_lazy"), "lazy") == {"a": "3", "b": "7", "inits": "1"}, "lazy init once")
sp = log("ex_spawn")
ok(kv(sp, "spawn") == {"rc": "3"}, "system() + WEXITSTATUS returns the script's exit code")
spawn_us = float(re.search(r"spawn_us=([\d.]+)", sp)[1])
embed_us = float(re.search(r"embed_us=([\d.]+)", sp)[1])
ok(spawn_us > 5000 and embed_us < 5 and spawn_us / embed_us > 1e4, f"spawn {spawn_us} us vs embed {embed_us} us")

print(f"check.py: {n_ok} checks OK  (init+fin {plain_ms:.0f} ms, spawn {spawn_us:.0f} us, embed {embed_us:.3f} us)")
