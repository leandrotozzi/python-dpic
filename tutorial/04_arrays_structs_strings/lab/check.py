#!/usr/bin/env python3
"""Asserts every number and tool behavior that 04_arrays_structs_strings/guide.html states.
Usage: cd lab && python3 check.py          (runs run.sh first, ~1 min)
       python3 check.py --no-run           (only parses build/)
"""
import pathlib, re, subprocess, sys

H = pathlib.Path(__file__).parent
B = H / "build"
if "--no-run" not in sys.argv:
    subprocess.run(["./run.sh"], cwd=H, check=True, capture_output=True)

def log(name):
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

# 1) Fixed-size arrays (Samples 12.18-12.21)
f = log("fib.log")
ok(kv(f, "fib2") == {"d0": "1", "d1": "1", "d19": "6765"}, "2-state fib")
ok(kv(f, "fib4") == {"d19": "6765", "unknown": "0"}, "4-state fib")
ok(kv(f, "fib4_bad") == {"d2": "00000002", "unknown": "0"}, "Verilator ignores bval=1 (2-state)")
ok(kv(f, "sum8") == {"sum": "140"}, "int[8] -> const int*")
ok(kv(f, "bytes_in") == {"le": "44332211"}, "byte[4] -> const char*, little-endian")
hdr = (B / "vl_fib" / "Vtop__Dpi.h").read_text()
for proto in ["void fib2(svBitVecVal* data)", "void fib4(svLogicVecVal* data)",
              "int sum8(const int* v)", "void bytes_in(const char* b, int* packed_le)"]:
    ok(proto in hdr, f"generated prototype: {proto}")

# 2) Open arrays (Samples 12.22-12.25)
o = log("openarr.log")
ok(kv(o, "fib_oa") == {"d19": "6765"}, "fib_oa")
ok(kv(o, "query_a") == {"left1": "6", "right1": "1", "low1": "1", "high1": "6", "inc1": "1", "size1": "6",
                        "left2": "8", "right2": "3", "size2": "6", "dims": "2", "bytes": "144"}, "Ex. 12.7 / Sample 12.24 queries")
ok(kv(o, "query_up") == {"left1": "0", "right1": "2", "low1": "0", "high1": "2", "inc1": "-1", "size1": "3",
                         "left2": "0", "right2": "3", "size2": "4", "dims": "2", "bytes": "48"}, "ascending ranges")
ok(kv(o, "c_sees") == {"a63": "9"}, "inout: C sees SV values")
ok(kv(o, "mydisplay") == {"a63": "18", "a13": "3", "a48": "32"}, "inout: SV sees C writes")
ok(kv(o, "flat") == {"v0": "1", "v_last": "10", "v_at_low": "0", "m0": "3", "m1": "4", "m6": "6"},
   "Verilator flat storage: low index first, row-major")
ok(kv(o, "sum_oa") == {"fixed": "55"}, "sum over [10:1]")
ok(kv(o, "ptr") == {"int": "1", "byte": "1"}, "svGetArrayPtr non-NULL for fixed arrays")
ok("index 1 out of bounds; 0 outside [10:1]" in o and kv(o, "oob") == {"ret": "-1"}, "out of range -> NULL + warning")
ok("called on 2 dimensional array using 1 dimensional function" in o and kv(o, "dimcheck") == {"ret": "-1"},
   "1-D access on 2-D handle -> NULL + warning")
ok(kv(log("k_fix.log"), "kinds") == {"sum": "10"}, "fixed actual OK")
ok("Unsupported: DPI argument of type DYNARRAYDTYPE" in log("k_dyn.build"), "dynamic array actual unsupported")
ok("Unsupported: DPI argument of type QUEUEDTYPE" in log("k_que.build"), "queue actual unsupported")
ok("Internal: Unexpected Call" in log("k_slice.build"), "slice actual: internal error")

# 3) Packed open arrays (Samples 12.26-12.27) and element layout
p = log("packed.log")
ok(kv(p, "sv") == {"bpack2": "1234567890abcdef", "bpack2_0": "90abcdef", "bpack2_0_0": "90"}, "Sample 12.26 SV prints")
ok("LOG c b64_2=1234567890abcdef" in p and "LOG c b64_9=0000000000000009" in p, "Sample 12.27 fixed loop reaches [9]")
ok(kv(p, "wide_sum") == {"total": "3ffffffff0000000100000002", "expect": "3ffffffff0000000100000002"}, "100-bit elements")
ok(kv(p, "put_wide") == {"w1": "f0000000000000000cafef00d"}, "svPutBitArrElem1VecVal")
ok(kv(p, "layout") == {"b8": "1", "s13": "2", "q64": "8", "w100": "16"}, "Verilator element storage bytes")
ok(kv(p, "raw8") == {"elem0": "44332211"}, "svBitVecVal* cast on bit[7:0] reads 4 elements")
ok(kv(p, "logic_get") == {"aval": "000000a5", "bval": "00000000"}, "logic element: bval written 0")
ok(kv(p, "bits") == {"ones": "3"}, "1-bit elements")

# 4) Structs (Samples 12.28-12.29)
s = log("structs.log")
ok(kv(s, "invert") == {"r": "ed", "g": "cb", "b": "a9"}, "book struct overlay (little-endian)")
ok(kv(s, "invert_bits") == {"r": "12", "g": "34", "b": "56"}, "portable invert")
ok(kv(s, "etype") == {"c": "00000800"}, "112-bit struct field via svGetPartselBit")
ok(kv(s, "make_hdr") == {"dst": "112255667788", "src": "b0b0a0a0a0a0", "etype": "86dd"}, "svPutPartselBit")
ok("Unsupported: DPI argument of type REFDTYPE 'ups_t'" in log("s_ups.build"), "unpacked struct unsupported")

# 5) Strings (Samples 12.30-12.31)
t = log("strings.log")
ok(kv(t, "strlen") == {"n": "10", "empty": "0"}, "input string")
ok(kv(t, "static_two") == {"a": "00001111", "b": "00002222"}, "Verilator copies the returned string at once")
ok(kv(t, "static_vars") == {"a": "0000aaaa", "b": "0000bbbb"}, "copy into SV string variable")
ok(kv(t, "ring") == {"a": "00000001", "b": "00000002"}, "ring buffer")
ok(kv(t, "name_of") == {"n": "BUSY"}, "output string -> const char**")
ok("LOG upcase s=MIXED CASE" in t, "inout string")
ok(kv(t, "keep") == {"kept": "first"}, "strdup copy survives")
sh = (B / "vl_strings" / "Vtop__Dpi.h").read_text()
for proto in ["int c_strlen(const char* s)", "const char* hex_static(int v)",
              "void name_of(int code, const char** name)", "void upcase(const char** s)"]:
    ok(proto in sh, f"generated prototype: {proto}")

# 6) Output vs inout direction
d = log("outdir.log")
ok(kv(d, "c_sees") == {"out0": "0"}, "output open array arrives zeroed in Verilator")
ok(kv(d, "outdir") == {"out": "0,7,0", "io": "5,7,5", "outf0_is5": "0", "outf1": "7"},
   "output overwrites every element; inout keeps unwritten ones")

# 7) Exercises
e = log("ex.log")
ok(kv(e, "ex1") == {"a10": "55", "a37": "-25"}, "ex1")
ok(kv(e, "ex2") == {"left1": "2", "right1": "5", "low1": "2", "high1": "5", "inc1": "-1", "size1": "4",
                    "left2": "3", "right2": "0", "inc2": "1", "size2": "4", "dims": "2", "bytes": "16"}, "ex2")
ok(kv(e, "ex5") == {"match": "1", "bin0": "6", "bin15": "3"}, "ex5")
ok(kv(e, "ex7") == {"dst": "123456789abc", "src": "aaaaaaaaaaaa", "etype": "0806"}, "ex7")
ok(kv(e, "ex9") == {"sum": "499500", "expect": "499500"}, "ex9")
ok(kv(e, "ex10") == {"rc": "0", "c00": "-16", "c01": "-22", "c10": "-25", "c11": "-34", "bad_rc": "-1"}, "ex10")
ok(kv(e, "ex11")["match"] == "1", "ex11")
ok("LOG ex12 left=00000010,000000f0,00000010,fffffff0" in e, "ex12 left")
ok("LOG ex12 right=00000000,00000000,00000000,00ffffff" in e, "ex12 right")
ok("LOG ex12 big=00000000" in e, "ex12 |n|>=32")
ok("RUN_RC=139" in log("bug_loop.log") and "LOG bug_loop" not in log("bug_loop.log"), "ex4 bug: segfault")
ok("address of stack memory associated with local variable 's' returned" in log("bug_str.build"), "ex8 bug: clang warns")

for n in ["fib", "openarr", "packed", "structs", "strings", "outdir", "ex", "k_fix"]:
    ok("BUILD_FAIL" not in log(f"{n}.build"), f"{n} builds")
print(f"check.py: {n_ok} checks OK")
