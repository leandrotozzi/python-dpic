#!/usr/bin/env python3
"""Asserts every number and behavior that 08_python_golden_model/guide.html states.
Usage: cd lab && python3 check.py            (runs run.sh first, ~1 min)
       python3 check.py --no-run             (only parses build/)
"""
import pathlib, re, subprocess, sys, timeit, zlib

H = pathlib.Path(__file__).parent
B = H / "build"
sys.path[:0] = [str(H), str(H / "ex")]
if "--no-run" not in sys.argv:
    subprocess.run(["./run.sh"], cwd=H, check=True, capture_output=True)


def log(name):
    return (B / f"{name}.log").read_text()


def build(name):
    return (B / f"{name}.build").read_text()


def kv(text, prefix):
    """'LOG <prefix> a=1 b=x' -> {'a': '1', 'b': 'x'} (first matching line)"""
    m = re.search(rf"^LOG {prefix} (.*)$", text, re.M)
    assert m, f"missing 'LOG {prefix}'"
    return dict(re.findall(r"(\S+?)=(\S*)", m[1]))


def err_of(text, tag):
    """'LOG <tag> value=V err=<free text>' -> (V, text)"""
    m = re.search(rf"^LOG {tag} value=(-?\d+) err=(.*)$", text, re.M)
    assert m, f"missing 'LOG {tag}'"
    return int(m[1]), m[2]


n_ok = 0


def ok(cond, msg):
    global n_ok
    assert cond, msg
    n_ok += 1


# 0) the Python models alone
r = subprocess.run([sys.executable, "golden.py"], cwd=H, capture_output=True, text=True)
ok("self-check OK" in r.stdout, "golden.py self-check")
ok(zlib.crc32(b"6789", zlib.crc32(b"12345")) == 0xCBF43926, "exercise 1: chaining")

# 1) CRC scoreboard, both backends, per message and per byte
crc = {k: log(k) for k in ("crc_py", "crc_py_byte", "crc_c", "crc_c_byte")}
for k, t in crc.items():
    ok(re.search(r"^PASS$", t, re.M), f"{k} PASS")
    ok(kv(t, "crc")["check_value"] == "cbf43926", f"{k}: CRC('123456789')")
d = {k: kv(t, "crc msgs=300") for k, t in crc.items()}
nbytes = d["crc_py"]["bytes"]
ok(all(v["bytes"] == nbytes and v["errors"] == "0" for v in d.values()), "same stimulus, no errors")
ok(d["crc_py"]["calls"] == "300" and d["crc_py_byte"]["calls"] == nbytes, "calls per message vs per byte")
st = log("crc_static")
ok(re.search(r"^PASS$", st, re.M) and "bytes=0 " in st and "check_value=00000000" in st,
   "exercise 5: static initializer -> 0 bytes tested, scoreboard still PASSes")

# 2) FIR: two instances, step vs block, bug injection identical in both backends
for k in ("fir_py", "fir_py_block", "fir_c", "fir_c_block"):
    t = log(k)
    ok(re.search(r"^PASS$", t, re.M), f"{k} PASS")
ok("calls=4096 " in log("fir_py") and "calls=16 " in log("fir_py_block"), "4096 per-sample calls vs 16 block calls")
ok(len({re.search(r"saturated=(\d+)", log(k))[1] for k in ("fir_py", "fir_c")}) == 1, "same saturation count")
# bug: GOLDEN_BUG=fir_trunc (Python, same binary) and -DMUTANT=1 (step 06's golden.c, rebuilt)
fm = {k: re.search(r"^LOG first_mismatch .*$", log(k), re.M)[0] for k in ("fir_py_bug", "fir_py_bugblk", "fir_c_bug")}
ok(len(set(fm.values())) == 1 and "sample=0 dut=-12612 model=-12613" in fm["fir_py_bug"], "bug: same first mismatch")
ok(all("errors=1729 " in log(k) for k in fm), "bug: 1729 mismatching samples")

# 3) wide ints (Python-only extra, checked against SV's own 200-bit multiply)
mx = format(((1 << 100) - 1) ** 2, "050x")
ok(re.search(r"^PASS$", log("wide_py"), re.M) and f"max_product={mx}" in log("wide_py"), "wide_py")

# 4) errors, chandle lifetime, buffers
e = log("err_py")
ok(err_of(e, "call_operator_add") == (42, "") and err_of(e, "call_math_gcd") == (2, ""), "generic bridge")
ok([err_of(e, t)[0] for t in ("live_before", "live_after_new", "live_after_free")] == [0, 1, 0], "chandle refcount")
ok(err_of(e, "missing_module")[1] == "no_such_module.f: ModuleNotFoundError: No module named 'no_such_module'", "missing module")
ok(err_of(e, "missing_func")[1] == "golden.nope: AttributeError: module 'golden' has no attribute 'nope'", "missing func")
ok(err_of(e, "raises")[1] == "fails: KeyError: 0", "exception")
ok("golden_py: fails: KeyError: 0" in e, "every Python failure is also printed at once (stderr)")
ok(err_of(e, "overflow") == (0, "big: OverflowError: int too big to convert"), "overflow")
ok(err_of(e, "keep_memoryview")[1] == "Fir8.block x: model kept a reference to a simulator buffer", "kept memoryview detected")
ok(err_of(e, "keep_numpy")[1] == "" and err_of(e, "kept0_after_sv_write")[0] == 1234, "numpy view: undetected alias")
ok("Verilog $stop" in e and "after_error" not in e and "RUN_RC=1" in e, "$error stops Verilator by default")
ok("ignored due to +verilator+error+limit" in log("err_py_lim") and "LOG after_error reached=1" in log("err_py_lim"),
   "+verilator+error+limit+N keeps going")

# 5) expected failures (Verilator 5.052)
ok("BUILD_FAIL" in build("dyn_fail") and "Unsupported: DPI argument of type DYNARRAYDTYPE" in build("dyn_fail"), "dyn array")
ok("BUILD_FAIL" in build("shape_fail") and "Shape of the argument does not match the shape of the parameter" in build("shape_fail"), "shape")
ok("BUILD_FAIL" in build("port_fail") and "Array element types are not equivalent" in build("port_fail"), "port")
ok("Unknown verilator comment" in build("pragma_fail"), "'// Verilator:' comment is a pragma")

# 6) exercises
ok(re.search(r"^PASS$", log("ex_shift"), re.M), "ex 2 shift")
s = log("ex_shiftreg")
ok(re.findall(r"^LOG shiftreg \w+=(\w+)$", s, re.M) == ["00000010", "00000100", "40000000", "80000000", "4"],
   "ex 9 shift register objects")
ok(re.search(r"^PASS$", log("ex_signed"), re.M) and "min_neg=8" + "0" * 24 in log("ex_signed"), "ex 10 signed")
from ex_models import neg100
ok(-(-(1 << 99)) > (1 << 99) - 1 and neg100(-(1 << 99)) == -(1 << 99), "ex 10: -(-2^99) needs the wrap")
ok("residue=2144df1c errors=0" in log("ex_crc_frames"), "ex 7 FCS residue")
ok(re.search(r"^PASS$", log("ex_lpf"), re.M) and "errors=7" in log("ex_lpf_noreset"), "ex 11 reset")

# 7) throughput (machine dependent: assert ratios, print the numbers for the guide)
P = {k: int(v) for k, v in re.findall(r"^LOG perf (\w+)=(\d+)$", log("perf_py"), re.M)}
C = {k: int(v) for k, v in re.findall(r"^LOG perf (\w+)=(\d+)$", log("perf_c"), re.M)}
ok("LOG perf done err=\n" in log("perf_py") + "\n", "perf: no model errors")
ok(P["first_call_us"] > 10000, "first Python call pays the interpreter + numpy import")
ok(C["fir_step_per_s"] > 20 * P["fir_step_per_s"], "C per-sample >> Python per-sample")
ok(P["fir_block_samples_per_s"] > 10 * P["fir_step_per_s"], "batching amortizes the crossing")
ok(P["crc_block_bytes_per_s"] > 100 * P["crc_byte_calls_per_s"], "crc: per block >> per byte")
ok(P["py_nop_calls_per_s"] > P["fir_step_per_s"], "the empty round trip bounds per-call throughput")
ok(P["system_python_calls_per_s"] < 100, "$system(python3 ...) costs tens of ms")
from golden import Fir8
f = Fir8([0x4000, -0x2000, 0x1000, 0x7FFF, -0x8000, 0x0800, 1, -1])
st_ = 20000 / timeit.timeit(lambda: f.step(1234), number=20000)
np_ = 5000 / timeit.timeit(lambda: f.step_np(1234), number=5000)
ok(st_ > 5 * np_, "plain-int step beats numpy step per sample")

print(f"check.py: {n_ok} asserts OK")
print("throughput (items/s)        Python        C")
for k in ("fir_step_per_s", "fir_block_samples_per_s", "crc_byte_calls_per_s", "crc_block_bytes_per_s"):
    print(f"  {k:26s} {P[k]:>12,} {C[k]:>12,}")
print(f"  py_nop_calls_per_s         {P['py_nop_calls_per_s']:>12,}")
print(f"  system_python_calls_per_s  {P['system_python_calls_per_s']:>12,}")
print(f"  first_call_us              {P['first_call_us']:>12,}")
print(f"  model only (no DPI): step {int(st_):,}/s, step_np {int(np_):,}/s")
