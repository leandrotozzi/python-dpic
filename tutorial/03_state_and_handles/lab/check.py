#!/usr/bin/env python3
"""Asserts every number and behavior that 03_state_and_handles/guide.html states.
Usage: cd lab && python3 check.py          (runs run.sh first, ~40 s)
       python3 check.py --no-run           (only parses build/)
"""
import pathlib, re, subprocess, sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["bash", "run.sh"], cwd=H, check=True, capture_output=True)


def log(name):
    return (B / name).read_text()


def kv(text, tag, nth=0):
    """'LOG <tag> a=1 b=x' -> {'a': '1', 'b': 'x'} (nth matching line)."""
    lines = re.findall(rf"^LOG {tag} (.*)$", text, re.M)
    assert len(lines) > nth, f"missing 'LOG {tag}' #{nth}"
    return dict(re.findall(r"(\S+?)=(\S+)", lines[nth]))


def outs(text, tag):
    """[(time, instance, out), ...] from 'LOG <tag> t=.. inst=.. out=..' lines."""
    return [(int(t), i, int(o)) for t, i, o in
            re.findall(rf"^LOG {tag} t=(\d+) inst=(\S+) out=(\d+)$", text, re.M)]


n_ok = 0
def ok(cond, msg):
    global n_ok
    assert cond, msg
    n_ok += 1


# 1) static C state shared by two module instances (Samples 12.7/12.8 as modules)
s = outs(log("static.log"), "static")
ok(s == [(10, "top.u2", 1), (10, "top.u1", 2), (30, "top.u2", 10), (30, "top.u1", 120),
         (50, "top.u2", 121), (50, "top.u1", 122), (70, "top.u2", 123), (70, "top.u1", 124)],
   f"static counter shared: {s}")

r = outs(log("static_reset.log"), "static")
ok(len(r) == 8 and all(o == 0 for _, _, o in r), "T6: reset held -> both print 0, sharing invisible")

# 2) per-instance state via chandle: C version and C++ version give identical, correct output
good = [(10, "top.u2", 1), (10, "top.u1", 1), (30, "top.u2", 10), (30, "top.u1", 120),
        (50, "top.u2", 11), (50, "top.u1", 121), (70, "top.u2", 12), (70, "top.u1", 122)]
for name in ("chandle", "cpp", "chandle_null", "booksig", "nocxxh"):
    ok(outs(log(f"{name}.log"), "inst") == good, f"{name}: independent counters")
c = log("chandle.log")
ok(kv(c, "null") == {"default_is_null": "1"}, "chandle defaults to null")
ok(kv(c, "live") == {"before_final": "2"}, "two live C objects before final")
ok(kv(c, "live", 1) == {"top_final": "2"}, "top's final ran before the instances' finals")
ok(kv(c, "final") == {"inst": "top.u2", "live_after_free": "1"} and
   kv(c, "final", 1) == {"inst": "top.u1", "live_after_free": "0"}, "each instance frees its object")
logs = lambda s: re.findall(r"^LOG .*$", s, re.M)
ok(logs(log("cpp.log")) == logs(c), "C and C++ models: identical LOG lines")
n = log("chandle_null.log")
ok("LOG cerr counter7 called with a null chandle" in n and kv(n, "null", 1) == {"rc": "-1"}, "null guard")
ok("RUN_RC=139" in log("booksig_null.log"), "book signature without null guard: SIGSEGV (rc 139)")

# 3) the generated prototype header catches the book's c7* parameter; missing extern "C" fails to link
h = (B / "booksigh.build").read_text()
ok("error: conflicting types for 'counter7'" in h and
   "extern int counter7(void* inst, svBitVecVal* out, const svBitVecVal* in, svBit reset, svBit load);" in h,
   "Vtop__Dpi.h vs c7*")
ok("treating 'c' input as 'c++'" in h, "Verilator compiles .c files with the C++ compiler")
x = (B / "nocxx.build").read_text()
ok('"_counter7_new", referenced from:' in x and "symbol(s) not found" in x and "BUILD_FAIL" in x,
   "no extern \"C\": unresolved C symbols at link time")
ok("Vdpiimwrap_counter7_free_TOP____024unit(unsigned long long)" in x, "Verilator passes chandle as 64-bit QData")

nm = subprocess.run(["nm", str(B / "vl_nocxx" / "nocxx.o")], capture_output=True, text=True).stdout
ok("T __Z12counter7_newv" in nm, "mangled name of counter7_new() without extern C")
ok(outs(log("nocxxh.log"), "inst") == good, "including Vtop__Dpi.h gives the wrappers C linkage")

# 4) TLM C++ model in an SV class: shallow copy, leak, free, dangling chandle
t = log("tlm.log")
ok(kv(t, "tlm") == {"get": "0"}, "126 -> 127 -> 0")
ok(kv(t, "shallow") == {"c1": "1", "c2": "1", "live": "1", "wrappers": "1"}, "shallow copy shares the C++ object")
ok(kv(t, "leak") == {"live": "101", "wrappers": "101"}, "100 leaked C++ objects")
ok(kv(t, "noleak") == {"live": "101"}, "free() before dropping: no new leaks")
ok(kv(t, "after_free") == {"c1_alive": "0", "c2_alive": "1", "live": "100"}, "c2 keeps a dangling chandle")

# 5) pure that lies: Verilator 5.052 still executes every call (LRM would allow removing them)
for name in ("pure", "honest"):
    ok(kv(log(f"{name}.log"), "pure") == {"a": "2", "b": "2", "c": "10", "calls": "13"}, f"{name}: 13 calls")

# 6) threads: which OS threads call imports
thr = {b: kv(log(f"{b}.log"), "threads") for b in ("thr1", "thr2", "thr2none", "thr2all")}
ok(thr["thr1"]["pure"] == "1" and thr["thr1"]["impure"] == "1", "single-threaded model")
ok(thr["thr2"]["pure"] == "2" and thr["thr2"]["impure"] == "1", "--threads 2: pure imports on 2 threads")
ok(thr["thr2none"]["pure"] == "1" and thr["thr2none"]["impure"] == "1", "--threads-dpi none: serialized")
ok(thr["thr2all"]["pure"] == "2" and thr["thr2all"]["impure"] == "1", "--threads-dpi all: same as pure here")
ok(len({d["acc"] for d in thr.values()}) == 1, "same result with any thread setting")

# 7) exercise solutions
e = log("ex2.log")
ok([kv(e, "ex2", k)[ch] for k, ch in enumerate("abcdef")] ==
   ["00000f00", "0000000f", "0000000f", "80000001", "00000002", "00000000"], "Ex. 12.2")
e = log("ex345.log")
addrs = re.findall(r"^LOG ex3 addr=(\S+)", e, re.M)
ok(len(addrs) == 4 and addrs[0] == addrs[2] and addrs[1] == addrs[3] and addrs[0] != addrs[1], "Ex. 12.3 addresses")
ok(kv(e, "ex345") == {"a": "00000020", "b": "04000000"}, "Ex. 12.3/12.5 values")
ok(kv(e, "ex345", 1) == {"calls_a": "2", "calls_b": "2", "total": "4"}, "Ex. 12.4 call counts")
ok(kv(log("ex6.log"), "ex6") == {"s1": "000000f0", "s2": "00000ab0", "total": "3"}, "Ex. 12.6")
cl = log("clone.log")
ok(kv(cl, "clone") == {"a": "5", "b": "6", "live": "2"} and
   kv(cl, "clone", 1) == {"b_after_a_free": "6", "live": "1"} and kv(cl, "clone", 2) == {"live_end": "0"}, "T8 deep copy")
f = kv(log("fifo.log"), "fifo")
ok(f["errors"] == "0" and int(f["pushes"]) + int(f["pops"]) + int(f["rejects"]) == 2000, "T9 FIFO model")
ok(kv(log("registry.log"), "registry") == {"a": "5", "b": "50", "c": "500", "n": "3", "name_b": "top.b"}, "T10 registry")

# 8) IEEE 1800-2023 6.14 chandle rules vs Verilator 5.052 lint (-Wall)
lint = {k: (B / f"chandle_rule{k}.lint").read_text() for k in range(1, 7)}
ok("WIDTHTRUNC" in lint[1] and "rc=1" in lint[1], "chandle -> int: only a width warning")
for k in (2, 3, 4, 5):
    ok("rc=0" in lint[k], f"rule {k}: accepted by Verilator (2, 4, 5 are illegal per LRM)")
ok("Unpacked data type 'chandle' in packed struct/union" in lint[6] and "rc=1" in lint[6], "packed struct: error")

fails = [p.name for p in B.glob("*.build") if "BUILD_FAIL" in p.read_text()]
ok(sorted(fails) == ["booksigh.build", "nocxx.build"], f"only the expected builds fail: {fails}")
print(f"PASS: {n_ok} checks")
