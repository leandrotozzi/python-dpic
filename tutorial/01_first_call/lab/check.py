#!/usr/bin/env python3
"""Step 01 lab: asserts every number and tool behavior that 01_first_call/guide.html states.
Usage: cd 01_first_call/lab && python3 check.py        (runs run.sh first, ~30 s with ccache)
       python3 check.py --no-run                       (only parses build/)
"""
import pathlib, re, subprocess, sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["bash", "run.sh"], cwd=H, check=True, capture_output=True)

def read(name):
    return (B / name).read_text()

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

# 1) hello: factorial, libm, renaming, libc, output argument -- identical with hdr.c (generated header)
for name in ("hello", "hdr"):
    t = read(f"{name}.log")
    fact = {int(i): int(f) for i, f in re.findall(r"^LOG fact i=(-?\d+) f=(-?\d+)", t, re.M)}
    ok(fact[10] == 3628800 and fact[12] == 479001600, f"{name}: 10!, 12!")
    ok(fact[13] == 1932053504 == (6227020800 % 2**32), f"{name}: 13! wraps mod 2^32")
    ok(fact[0] == 1 and fact[-1] == 1, f"{name}: i<=1 -> 1")
    ok(kv(t, "libm") == {"fabs": "1.500", "sin30": "0.500000", "pow": "1024.0"}, f"{name}: libm direct")
    ok(kv(t, "rename") == {"fexpect": "42"}, f"{name}: \\expect = fexpect")
    ok(kv(t, "access") == {"sv": "0", "none": "-1"}, f"{name}: libc access()")
    ok(kv(t, "addmul") == {"p": "42", "s": "13"}, f"{name}: output int")

# 2) the build pipeline: .c compiled by the C++ compiler, generated header, per-import wrappers
# (clang also warns "treating 'c' input as 'c++'", but only on a ccache miss, so it is not asserted)
mk = (B / "vl_hello/Vtop.mk").read_text()
ok(re.search(r"hello\.o: hello\.c\s*\n\t.*\$\(CXX\)", mk), "hello.c built with $(CXX)")
dpih = (B / "vl_hello/Vtop__Dpi.h").read_text()
for proto in ("extern int factorial(int i);", "extern int addmul(int a, int b, int* sum);",
              "extern int expect();", "extern double pow(double x, double y);",
              "extern int access(const char* path, int mode);"):
    ok(proto in dpih, f"Vtop__Dpi.h has {proto}")
ok('extern "C" {' in dpih, "Vtop__Dpi.h wraps prototypes in extern C")
root = (B / "vl_hello/Vtop___024root__0.cpp").read_text()
ok("Vdpiimwrap_top__DOT__addmul_TOP" in root and "addmul(a__Vcvt, b__Vcvt, &sum__Vcvt)" in root,
   "import wrapper passes a temporary for the output and copies it back")

# 3) expected failures
ne = read("noextern.build")
ok("Undefined symbols" in ne and '"_factorial"' in ne and "BUILD_FAIL" in ne, "no extern C -> undefined _factorial")
ok("__Z9factoriali" in subprocess.run(["nm", str(B / "vl_noextern/noextern.o")], capture_output=True, text=True).stdout,
   "C++ mangled name __Z9factoriali")
ms = read("missing.build")
ok('"_addmul", referenced from' in ms and '"_factorial"' not in ms, "missing symbol: only _addmul undefined")
ok("Undefined symbols" in read("ex12.build") and '"_factorial"' in read("ex12.build"), "static -> internal linkage -> undefined")
ok(kv(read("mismatch.log"), "mismatch") == {"v": "4294967301", "negate": "4294967291", "expected": "-4294967301"},
   "SV longint vs C int: C sees low 32 bits (5), returns -5 zero-extended")
mh = read("mmhdr.build")
ok("functions that differ only in their return type cannot be overloaded" in mh, "header turns mismatch into compile error")
mh2 = read("mmhdr2.build")
ok('"_negate", referenced from' in mh2 and "BUILD_FAIL" in mh2, "header without extern C: C++ overload, link error")
ok("syntax error, unexpected expect" in read("keyword.build"), "expect is a keyword")
ok("Unsupported DPI type 'DPI': Use 'DPI-C'" in read("legacy.build"), "\"DPI\" unsupported in Verilator")
ok("Duplicate declaration of DPI function with different signature: 'twice'" in read("dup.build"), "dup signature")
ok("functions that differ only in their return type cannot be overloaded" in read("ex5.build")
   and "size_t   strlen" in read("ex5.build"), "strlen direct import collides with <string.h>")

# 4) pure: Verilator 5.052 still calls every time (the LRM would allow skipping)
pu = read("pure.log")
calls = dict(re.findall(r"^LOG pure case=(\S+)\s+calls=(\d+)", pu, re.M))
ok(calls == {"unused": "1", "twice": "2", "loop4": "4", "raw_twice": "2"}, f"pure call counts {calls}")

# 5) packages
pk = read("pkg.log")
ok(len(re.findall(r"^LOG pkg who=top\.c[12] f6=720", pk, re.M)) == 2 and "LOG pkg who=top f7=5040" in pk, "package import")

# 5b) imports in combinational logic: one call per evaluation per call site
ok(kv(read("comb.log"), "comb t=1") == {"calls": "2"}, "comb: initial evaluation of both call sites")
ok(kv(read("comb.log"), "comb t=101") == {"calls": "22", "x": "10", "y": "10", "z": "11"}, "comb: 2 + 10 changes x 2 sites")
# ref in an import: illegal per LRM, Verilator accepts it silently as a pointer
ok("extern void bump(int* x);" in (B / "vl_ref/Vtop__Dpi.h").read_text(), "ref accepted, mapped to int*")
ok('"_bump", referenced from' in read("ref.build") and "%Error: ref.sv" not in read("ref.build"), "ref: no Verilator error")

# 5c) LRM 35.5.2: pure only on nonvoid functions without output/inout; never on tasks.
#     Verilator 5.052 accepts all three illegal forms silently.
for n in ("pr_void", "pr_task", "pr_out"):
    ok("%Error" not in read(f"{n}.build") and "BUILD_FAIL" not in read(f"{n}.build"), f"{n}: accepted, no error")
ok("LOG prule case=void built=1" in read("pr_void.log") and "LOG prule case=task built=1" in read("pr_task.log"),
   "pure void function / pure task run")
ok(kv(read("pr_out.log"), "prule case=out") == {"r": "3", "b": "4"}, "pure with output: runs, output written")
# 5d) LRM 35.4/35.5.4: one c_identifier in two scopes. Same signature: legal. Different qualifier: error.
ok(kv(read("cid.log"), "cid") == {"top": "4", "u": "6"}, "same C name, two SV names, two scopes")
cb = read("cid_bad.build")
ok("Duplicate declaration of DPI function with different signature: 'twice'" in cb and "BUILD_FAIL" in cb,
   "context vs non-context on one C name: rejected")

# 6) exercises
ok("PASS ex1" in read("ex1.log") and "FAIL" not in read("ex1.log"), "Ex. 12.1 shift_c")
ok(kv(read("ex2.log"), "fact64") == {"f13": "6227020800", "f20": "2432902008176640000", "f21": "-4249290049419214848"}, "ex2")
ok((51090942171709440000 % 2**64) - 2**64 == -4249290049419214848, "21! mod 2^64 as signed")
ok(kv(read("ex5f.log"), "strlen") == {"empty": "0", "hello": "5", "len": "5"}, "ex5 fix")
g = re.findall(r"^LOG gcd (.*)$", read("ex6.log"), re.M)
ok(g == ["a=1071 b=462 g=21 steps=3", "a=17 b=5 g=1 steps=3", "a=8 b=0 g=8 steps=0"], f"ex6 {g}")
ok(kv(read("ex7.log"), "db") == {"c": "0.7079457844", "sv": "0.7079457844", "same": "1", "back": "-3.000000"}, "ex7")
ok("PASS ex11" in read("ex11.log") and kv(read("ex11.log"), "popcount")["errors"] == "0", "ex11")

print(f"check.py: {n_ok} checks passed")
