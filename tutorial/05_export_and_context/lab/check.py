#!/usr/bin/env python3
"""Asserts every result that 05_export_and_context/guide.html states.
Usage: cd lab && python3 check.py           (runs run.sh first)
       python3 check.py --no-run            (only parses build/)
"""
import pathlib, re, subprocess, sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["./run.sh"], cwd=H, check=True, capture_output=True)

def log(name):
    return (B / f"{name}.log").read_text()

def build(name):
    return (B / f"{name}.build").read_text()

def logs(text, tag):
    """all 'LOG <tag> k=v ...' lines -> list of dicts"""
    return [dict(re.findall(r"(\S+?)=(\S+)", m)) for m in re.findall(rf"^LOG {tag} (.*)$", text, re.M)]

n_ok = 0
def ok(cond, msg):
    global n_ok
    assert cond, msg
    n_ok += 1

# --- scopes (Samples 12.34/12.46): same C routine, the caller's scope decides which export runs
s = log("scopes")
ok(logs(s, "c") == [{"scope": "top.b1", "caller": "scopes.sv:9"}, {"scope": "top", "caller": "scopes.sv:19"}],
   "c_display sees the caller scope + svGetCallerInfo")
ok(logs(s, "sv") == [{"where": "top.b1.sv_display"}, {"where": "top.sv_display"}], "export resolved per scope")
ok("extern void sv_display();" in (B / "vl_scopes" / "Vtop__Dpi.h").read_text(), "generated header lists exports")

# --- svSetScope / by name / user data (Samples 12.48–12.50)
s = log("setscope")
ok(logs(s, "c")[0] == {"called_from": "top.b2"} and logs(s, "c")[2] == {"called_from": "top.b1"},
   "Verilator runs b2's initial before b1's")
ok({"now_in": "top.b1", "prev": "top"} in logs(s, "c"), "svSetScope returns the previous scope")
ok(logs(s, "sv")[-2:] == [{"where": "top.b1.sv_display"}, {"where": "top.b2.sv_display"}],
   "top's call lands in the last saved scope (b1), by_name lands in b2")
ok(logs(s, "byname") == [{"name": "top.b2", "found": "1"}, {"name": "TOP.top.b2", "found": "0"},
                         {"name": "b2", "found": "0"}, {"name": "top.nope", "found": "0"}], "svGetScopeFromName names")
ok(logs(s, "bump") == [{"where": "top.b2", "n": "1"}, {"where": "top.b1", "n": "1"}, {"where": "top", "n": "4"}],
   "svPutUserData: one counter per scope")

# --- missing context
s = log("noctx")
ok("%Warning: DPI C Function called by Verilog DPI import with missing 'context' keyword." in s, "warning text")
ok("LOG c scope=NULL" in s, "no scope at all")
ok("Testbench C called 'sv_hello' but scope wasn't set, perhaps due to dpi import call without 'context', "
   "or missing svSetScope. See IEEE 1800-2023 35.5.3." in s and "RUN_RC=1" in s and "LOG sv after" not in s,
   "fatal error text")
s = log("stale")
ok("LOG c scope=top.o" in s and "LOG sv hello where=top.o.sv_hello" in s and "Warning" not in s,
   "stale scope: WRONG export runs, silently")

# --- tasks
s = log("xtask")
ok([d["o"] for d in logs(s, "c") if "o" in d] == ["0", "10", "20"] and "LOG c disabled_state=0" in s
   and "LOG sv calls=3 t=0" in s, "zero-time exported task from an imported task")
hdr = (B / "vl_xtask" / "Vtop__Dpi.h").read_text()
ok("extern void sv_task(int i, int* o);" in hdr and "extern int c_task(int n);" in hdr,
   "Verilator: exported task -> void (LRM: int), imported task -> int")
ok("LOG sv waited t=0" in log("fn2task") and "LOG sv after t=0" in log("fn2task"),
   "imported FUNCTION calling an exported TASK: Verilator accepts it")
for v, line in [("xt_delay", 17), ("xt_at", 13), ("xt_nested", 9)]:
    ok(f"%Error-UNSUPPORTED: xtime.sv:{line}:5: Unsupported: Timing controls inside DPI-exported tasks" in build(v)
       and "BUILD_FAIL" in build(v), f"{v}: timing in exported task rejected")

# --- pure / combinational probes
ok("LOG pure calls=7 r=294" in log("pure") and "LOG gen calls=7 b=294" in log("pure"),
   "pure: no call elided, no CSE")
c = logs(log("comb"), "comb")[0]
ok(c["pure_calls"] == c["gen_calls"] == "11" and c["yp"] == "25", "comb: 11 C calls for 5 input changes")

b = {d["kind"]: float(d["ns_per_call"]) for d in logs(log("bench"), "bench") if "kind" in d}
ok(abs(b["pure"] - b["gen"]) < 0.5 * b["gen"] + 0.5, f"pure ~ generic {b}")
ok(b["context"] > 2.5 * b["gen"], f"context costs several x {b}")
ok(b["context+export"] > 1.5 * b["context"], f"each export call adds about one context switch {b}")
print("bench ns/call:", b)

o = logs(log("outarg"), "outarg")[0]
ok(o["before"] == "7" and (o["after1"], o["after2"]) != ("7", "7"), f"unwritten output = garbage temp {o}")
print("outarg garbage:", o)
ok("skip_out(k__Vcvt, &o__Vcvt);" in (B / "vl_outarg" / "Vtop___024root__0.cpp").read_text(), "outputs go through a temp")

# --- memory models
ok("LOG c read addr=12 data=34 exp=34" in log("mem_func") and "LOG memf size=100 m12=34 m99=8 errs=0 t=0" in log("mem_func"),
   "Samples 12.37-12.39 (functions)")
mt = build("mem_task")
ok("mem_task.sv:15:5: Unsupported: Timing controls inside DPI-exported tasks" in mt and
   "mem_task.sv:18:5: Unsupported" in mt and "BUILD_FAIL" in mt, "Sample 12.40 rejected by Verilator")
s = log("mem_oop")
ok("LOG c read mem=1 addr=22 data=0 exp=44 MISMATCH" in s and "LOG memoop n=2 m0_12=34 m1_12=88 m0_99=18 errs=1" in s,
   "Samples 12.43-12.45: book's file reads an unwritten location")
ok("Static variable initializer" not in build("mem_oop"), "mem_build is automatic")
s = log("mem_pull")
ok([(d["mem"], d["data"], d["t"]) for d in logs(s, "c")] == [("1", "0", "50"), ("0", "34", "70"), ("1", "88", "90")],
   "pull model: reads at 50/70/90 ns")
ok("LOG pull errs=1 t=90" in s and int(logs(s, "pull")[0]["ticks"]) >= 89, "pull: 3x10+3x20 ns, TB kept running")

# --- exercises
ok([(d["n"], d["o"]) for d in logs(log("ex12_8"), "ex8")] ==
   [("4", "00000f00"), ("-4", "0800000f"), ("0", "800000f0"), ("40", "00000000"), ("-31", "00000001")], "Ex. 12.8")
ok(logs(log("ex12_10"), "ex10") == [{"idx": "0", "result": "00000010"}, {"idx": "1", "result": "00000001"},
                                    {"idx": "2", "result": "deadbeef"}, {"n": "3"}], "Ex. 12.9/12.10")
ok(re.findall(r"^LOG who (\S+)", log("predict"), re.M) == ["top.who", "top.m.l.who", "top.m.who"], "predict")
s = log("report")
ok("[10] %Error: report.sv:8: Assertion failed in top.sv_report: [C model @ ex/report.sv:12] got 4 exp 5" in s
   and "[20] %Error" in s and "ex/report.sv:13] got 7 exp 9" in s and "LOG report done" in s, "report via $error")
s = log("broadcast")
ok(sorted(d["hello"] for d in logs(s, "bcast") if "hello" in d) == ["top.gen[0].u", "top.gen[1].u", "top.gen[2].u"]
   and "LOG bcast sum=303" in s, "generate names + per-scope user data")
ok("LOG pull1 errs=0 t=40" in log("pull1"), "Sample 12.40 as a pull model: 10+10+20 ns")
ok("LOG bug errs=3 same=1 size0=0" in log("sib"), "static initializer bug: one shared size-0 Memory")

print(f"check.py: {n_ok} checks PASS")
