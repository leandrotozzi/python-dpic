#!/usr/bin/env python3
"""Asserts every number and behavior that 02_data_types/guide.html states.
Usage: cd 02_data_types/lab && python3 check.py        (runs run.sh first, ~20-60 s)
       python3 check.py --no-run                       (only parses build/)
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


# 1) scalar mapping (types)
t = log("types.log")
ok(kv(t, "sizeof") == {"char": "1", "short": "2", "int": "4", "longlong": "8", "float": "4", "double": "8",
                       "svBit": "1", "svLogic": "1", "svBitVecVal": "4", "svLogicVecVal": "8", "ptr": "8",
                       "char_signed": "1"}, "sizeof table")
ok(kv(t, "byte") == {"min": "-128", "max": "127"}, "byte round trip")
ok(kv(t, "ubyte") == {"max": "255"}, "byte unsigned")
ok(kv(t, "short") == {"min": "-32768", "max": "32767"} and kv(t, "ushort") == {"max": "65535"}, "shortint")
ok(kv(t, "int") == {"min": "-2147483648", "max": "2147483647"} and kv(t, "uint") == {"max": "4294967295"}, "int")
ok(kv(t, "long") == {"min": "-9223372036854775808", "max": "9223372036854775807"}, "longint")
ok(kv(t, "ulong") == {"max": "18446744073709551615"}, "longint unsigned")
ok(kv(t, "real") == {"v": "0.10000000000000001"}, "real = double")
ok(kv(t, "bit") == {"v0": "0", "v1": "1"}, "bit")
ok(kv(t, "logic") == {"v0": "0", "v1": "1", "vx": "0", "vz": "0"}, "Verilator: X and Z arrive as 0")
ok(t.count("LOG c_logic v=0") == 3, "C sees 0 for 0, X and Z")
ok(kv(t, "string") == {"len": "10", "empty": "0"}, "string input")
ok(kv(t, "chandle") == {"get": "42", "null_is_null": "1", "h_is_null": "0", "h_eq_null": "0"}, "chandle")
ok(kv(t, "bit7") == {"v": "100"} and kv(t, "enum") == {"v": "BUSY"} and "LOG c_enum v=-2" in t, "bit7 / enum")

# shortreal: Verilator promotes it to real and passes a double; a float on the C side reads garbage
hdr = (B / "vl_types/Vtop__Dpi.h").read_text()
ok("extern double rt_sreal(double v);" in hdr, "Verilator prototype: shortreal -> double")
ok("extern char rt_byte(char v);" in hdr and "extern svBitVecVal rt_bit7(const svBitVecVal* v);" in hdr, "byte/bit7 protos")
ok("Unsupported: shortreal being promoted to real" in log("types.build"), "SHORTREAL warning")
c_sreal = float(kv(t, "c_sreal")["v"])
ok(abs(c_sreal - 0.1) > 0.01, "float-declared C function reads garbage")
fx = log("types_fix.log")
ok(kv(fx, "c_sreal") == {"v": "0.10000000000000001"} and kv(fx, "sreal") == {"v": "0.10000000000000001"},
   "double on the C side: exact 0.1 (no float rounding)")
ok("functions that differ only in their return type cannot be overloaded" in log("types_hdr.build"),
   "including Vtop__Dpi.h turns the mismatch into a compile error")
ok("Unsupported tristate construct: ARG" in log("zlit.build"), "1'bz literal argument rejected")

# plain char unsigned (like ARM Linux): SV round trip still fine, C-side interpretation wrong
u = log("types_uchar.log")
ok(kv(u, "sizeof")["char_signed"] == "0" and "LOG c_byte v=128" in u, "-128 seen as 128 in C")
ok(kv(u, "byte") == {"min": "-128", "max": "127"} and "LOG c_enum v=254" in u, "round trip ok, enum -2 seen as 254")

# 2) packed vectors (vec)
v = log("vec.log")
ok(kv(v, "v40") == {"w0": "3456789a", "w1": "00000012"}, "40-bit: word 0 = bits 31:0, unused bits 0 on input")
ok(kv(v, "dump") == {"tag": "v200", "n": "7", "w0": "00000001", "w1": "00000000", "w2": "00000000", "w3": "00000000",
                     "w4": "00000000", "w5": "00000000", "w6": "000000c7"}, "200-bit: 7 words, MS byte in w6")
ok(kv(v, "s40") == {"w0": "fffffffe", "w1": "000000ff"}, "signed 40-bit -2: NOT sign-extended in word 1")
ok(kv(v, "dirty") == {"d": "ffffffffff", "eq": "1", "plus1": "0000000000"}, "Verilator masks dirty upper bits")
ok(kv(v, "add200") == {"ok": "1"}, "200-bit add")
ok(kv(v, "partsel_in") == {"w0": "00003039", "w2": "00000000", "w6": "00000000"}, "output arrives with stale data")
ok(kv(v, "partsel")["f"] == "dead" and kv(v, "partsel")["w_ok"] == "0", "svPutPartselBit leaves the stale words")
ok(kv(v, "partsel")["w"].endswith("2fbbc00000000000003039"), "field placed at bit 70, stale 0x3039 below")
ok("LOG sign8_c raw=00000080 macro=128 right=-128" in v and "LOG sign8_c raw=000000ff macro=255 right=-1" in v,
   "SV_GET_SIGNED_BITS tests bit N, not N-1")
ok(kv(v, "ldump") == {"w0.aval": "34567800", "w0.bval": "00000000", "w1.aval": "00000012", "w1.bval": "00000000"},
   "4-state input in Verilator: x/z -> aval 0, bval 0")
ok(kv(v, "lwrite") == {"l8": "01010101"}, "bval written by C is dropped: only aval survives")

# 3) directions (dir)
d = log("dir.log")
peek = kv(d, "c_peek")["in"]
ok(peek != "77" and kv(d, "peek") == {"o": "1"}, "output: C does not see the SV value (77)")
sk = kv(d, "c_skip")
ok(kv(d, "skip") == {"o": sk["o_in"], "v": sk["v_in"]} and sk["o_in"] != "77", "unwritten output: SV gets the junk")
ok(sk["v_in"] == "1234567890", "the junk is the previous call's 40-bit temp")
ok(kv(d, "inout") == {"io": "11", "vv": "0100000000"}, "inout carry into bit 32")
ok(kv(d, "c_alias") == {"i_after_write": "5"} and kv(d, "alias") == {"x": "100"}, "input is a copy")
ok(kv(d, "badbit") == {"b": "0", "l": "0", "b_eq1": "0", "b_plus0": "0"}, "scalar output masked to bit 0")
w = (B / "vl_dir/Vtop___024unit__0.cpp").read_text()
ok("svBitVecVal v__Vcvt[2];\n    c_skip_out(&o__Vcvt, v__Vcvt);" in w, "uninitialized temp in the wrapper")
ok("VL_SET_Q_SVBV(40, v, v__Vcvt + 0);" in w and "b = (1U & (b__Vcvt));" in w, "copy-back masks")

# 4) Sample 12.11/12.12 on a 2-state simulator
c4 = log("counter4.log")
ok("c4err" not in c4, "Verilator never reports X/Z")
ok(kv(c4, "c4 step=xreset") == {"out": "1"}, "X reset seen as 0: counter counts to 1")
ok(kv(c4, "c4 step=xload") == {"out": "0"}, "zzxx load seen as 0")

# 5) return types and prototypes
def proto(n):
    return (B / "proto" / f"{n}.out").read_text()
ok("extern svBitVecVal f();" in proto("r_bit32"), "bit[31:0] result -> svBitVecVal")
ok("may not return a > 32 bits wide type" in proto("r_bit33"), "bit[32:0] result rejected")
ok("may not return a 4-state type other than a single 'logic'" in proto("r_logic7"), "logic[6:0] result rejected")
ok("may not return a 4-state type" in proto("r_integer"), "integer result rejected")
ok("extern svLogic f();" in proto("r_logic") and "extern const char* f();" in proto("r_string"), "logic/string results")
for n in ("a_integer", "a_time", "a_logic1"):
    ok("extern void f(const svLogicVecVal* a);" in proto(n), f"{n} -> svLogicVecVal*")
ok("extern void f(const char** a);" in proto("a_ostring"), "output string -> const char**")
ok("extern void f(int* a);" in proto("a_ref") and "Error" not in proto("a_ref"), "ref accepted silently")
ok("extern void f(double a, double* b);" in proto("a_sreal"), "shortreal args -> double")

# svDpiVersion (H.10.1.3): the canonical representation of IEEE 1800-2005 and later
ok(kv(log("ver.log"), "ver") == {"dpi": "1800-2005"}, "svDpiVersion")

# 6) exercise solutions
for n in ("ex_shift", "ex_popcount", "ex_sext", "ex_partsel", "ex_isneg", "ex_isneg_u", "ex_mul128"):
    ok(re.search(r"^PASS$", log(f"{n}.log"), re.M), f"{n} PASS")
ok(kv(log("ex_shift.log"), "shift_naive") == {"n32": "800000f1", "n40": "0000f100"}, "x86 masks the shift count")
ok(kv(log("ex_sext.log"), "ex_sext") == {"bad_m2": "1099511627774", "good_m2": "-2", "errs": "0"}, "sext")
ok(kv(log("ex_isneg.log"), "ex_isneg")["bad_m5"] == "1" and kv(log("ex_isneg_u.log"), "ex_isneg")["bad_m5"] == "0",
   "plain char: bad version breaks only with unsigned char")
ok(kv(log("ex_mul128.log"), "ex_mul128")["max"] == "fffffffffffffffe0000000000000001", "max product")
ok(kv(log("ex_popcount.log"), "ex_popcount")["all_ones"] == "200", "popcount all ones")
ok(kv(log("ex_xz.log"), "ex_xz") == {"verilator": "0"} and kv(log("ex_xz_unit.log"), "ex_xz") == {"unit": "24"}, "xz")
ok("c4err" not in log("ex_c4fix.log") and kv(log("ex_c4fix.log"), "c4 step=reset") == {"out": "0"}, "c4 fix")
ok("extern void e1(unsigned char a, long long* b, const svBitVecVal* c, svLogicVecVal* d, const char* e, "
   "svBit* f, void** g);" in log("ex_protos.h"), "exercise 1 prototypes")

print(f"OK: {n_ok} checks passed")
