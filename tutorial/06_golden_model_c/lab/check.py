#!/usr/bin/env python3
"""Asserts everything 06_golden_model_c/guide.html states about the lab.
Usage: cd lab && python3 check.py            (runs run.sh first, ~1-2 min)
       python3 check.py --no-run             (only parses build/)
"""
import pathlib, re, subprocess, sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["./run.sh"], cwd=H, check=True, capture_output=True)

def log(name):
    return (B / f"{name}.log").read_text()

def kv(text, prefix):
    """'LOG <prefix> a=1 b=x' -> {'a': '1', 'b': 'x'} (first matching line)"""
    m = re.search(rf"^LOG {prefix} (.*)$", text, re.M)
    assert m, f"missing 'LOG {prefix}'"
    return dict(re.findall(r"(\S+?)=(\S+)", m[1]))

n_ok = 0
def ok(cond, msg):
    global n_ok
    assert cond, msg
    n_ok += 1

for b in B.glob("*.build"):
    if b.name not in ("dup.build", "nohdr.build"):
        ok("BUILD_FAIL" not in b.read_text(), f"build failed: {b.name}")
dup = (B / "dup.build").read_text()
ok("BUILD_FAIL" in dup and "duplicate symbol" in dup, "two models linked together: duplicate symbols")
nohdr = (B / "nohdr.build").read_text()
ok("BUILD_FAIL" in nohdr and "Undefined symbols" in nohdr, "C++ model without the generated header: mangled names")

# --- FIR: clean runs, reproducibility, both checking modes see the same stimulus
s1, b1, s2 = kv(log("fir_s1"), "fir_run"), kv(log("fir_b1"), "fir_run"), kv(log("fir_s2"), "fir_run")
for n in ("fir_s1", "fir_b1", "fir_s2", "fir_fast_s", "fir_fast_b", "fir_c_ref", "fir_cpp"):
    ok("PASS fir8" in log(n), f"{n} should pass")
ok(s1["digest"] == b1["digest"], "same seed -> same stimulus, whatever the checking mode")
ok(s1["digest"] != s2["digest"], "different seed -> different stimulus")
ok(kv(log("fir_s1"), "fir_sb")["compared"] == "500", "stream compares every output")
ok(int(s1["sat"]) > 50, "corner weights produce saturated outputs")

# --- fake DUT bug: output #100 corrupted
for n in ("fir_flip", "fir_flip_b"):
    sb = kv(log(n), "fir_sb")
    ok(sb["errors"] == "1" and sb["first"] == "100", f"{n}: exactly one mismatch at idx 100")
    ok(re.search(r"^LOG mismatch model=fir8 kind=value idx=100 x=-?\d+ exp=-?\d+ got=-?\d+$", log(n), re.M), n)

# --- mutated golden models
m1, m2, m4 = (kv(log(n), "fir_sb") for n in ("fir_m1", "fir_m2", "fir_m4"))
r1 = kv(log("fir_m1"), "fir_run")
unsat = int(m1["compared"]) - int(r1["sat"])
ok(0.45 < int(m1["errors"]) / unsat < 0.55, "truncation differs on ~half of the non-saturated outputs")
ok(m2["errors"] == r1["sat"], "wrap vs saturate differs on exactly the saturated outputs")
ok(int(m4["errors"]) > 1000 and int(m4["first"]) > 0, "32-bit accumulator: caught, but not on sample 0")
ok(kv(log("fir_cpp"), "fir_run")["digest"] == kv(log("fir_c_ref"), "fir_run")["digest"], "C++ swap: same run")

# --- CRC
ok(kv(log("crc_s1"), "crc_check")["model"] == "cbf43926", "catalogue check value")
cs, cb = kv(log("crc_s1"), "crc_sb"), kv(log("crc_b1"), "crc_sb")
ok("PASS crc32" in log("crc_s1") and "PASS crc32" in log("crc_b1"), "crc clean runs")
ok(cb["compared"] == cb["frames"] == "12" and int(cs["compared"]) > 10 * int(cb["compared"]),
   "stream checks every cycle, batch once per frame")
f, fb = kv(log("crc_flip"), "crc_sb"), kv(log("crc_flip_b"), "crc_sb")
ok(f["errors"] == "1" and f["first"] == "500", "stream catches the glitch on cycle 500")
ok(fb["errors"] == "0" and "PASS crc32" in log("crc_flip_b"), "batch is blind to a mid-frame glitch")
c3, c3b = kv(log("crc_m3"), "crc_sb"), kv(log("crc_m3_b"), "crc_sb")
ok(int(c3["errors"]) > 10 and int(c3b["errors"]) >= 1, "bad table entry caught in both modes")
ok(int(c3["first"]) < int(c3b["first"]), "stream localizes earlier than batch")

# --- cost: a DPI call into C is a plain function call; the solver and the simulator dominate
bench = {m[0]: float(m[1]) for m in re.findall(r"^LOG bench name=(\S+) n=\d+ ns_per_item=([\d.]+)", log("bench"), re.M)}
ok(bench["dpi_nop"] < 20 and bench["fir8_step"] < 50 and bench["crc32_update"] < 50, "DPI call into C: ns, not us")
ok(bench["sv_fir_step"] > bench["fir8_step"], "the same FIR in SV (Verilator) is slower than in C")
fs, fbt = kv(log("fir_fast_s"), "fir_run"), kv(log("fir_fast_b"), "fir_run")
ok(200_000 * bench["fir8_step"] * 1e-6 < 0.05 * int(fs["wall_ms"]), "DPI time < 5% of the run")
ok(int(s1["wall_ms"]) / 500 > 20 * int(fs["wall_ms"]) / 200_000, "randomize() per item costs >20x the $urandom TB")

# --- exercises
ok("PASS shift" in log("shift"), "Ex. 12.1-12.4")
ok(len(set(re.findall(r"inst=(0x[0-9a-f]+)", log("shift")))) == 2, "two instances, two addresses")
ok("PASS residue" in log("residue") and "bad=0" in log("residue"), "CRC residue 0x2144DF1C")
ok("crc32_msg: len=300 outside buffer of 256" in log("len") and "RUN_RC=134" in log("len"), "len guard aborts")

res = (B / "results.txt").read_text()
ok(re.search(r"7 PASS fir8", res) and re.search(r"3 PASS crc32", res) and re.search(r"5 FAIL fir8", res)
   and re.search(r"3 FAIL crc32", res), "12 PASS / 8 FAIL, the FAILs being the intended ones")

print(f"OK {n_ok} checks")
print("bench ns/item:", {k: v for k, v in bench.items()})
print("fir fast wall_ms stream/batch:", fs["wall_ms"], fbt["wall_ms"], "| randomize run:", s1["wall_ms"], "ms for 500")
