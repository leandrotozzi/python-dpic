"""Python golden models for the shared DUTs in tutorial/common/rtl.

Called from SystemVerilog through golden_py.c (DPI-C -> embedded CPython), which implements the
contract of step 06 (06_golden_model_c/lab/golden_pkg.sv). Plain Python on purpose: every function
can be unit-tested with `python3 golden.py` without any simulator.
"""
import os
import zlib
import numpy as np

# Bug injection: GOLDEN_BUG=fir_trunc (environment, no SV change, like -DMUTANT=1 for golden.c)
# or set_bug() at run time from SV (py_extra_pkg::py_set_bug).
BUG = set(os.environ.get("GOLDEN_BUG", "").split(",")) - {""}
KEPT = None          # see Fir8.block, keep_numpy


def set_bug(name):
    BUG.clear() if name == "none" else BUG.add(name)


# ---------------------------------------------------------------- CRC-32 (crc32_stream.sv)
def crc32_update(crc, data):
    """Running CRC: crc is the CRC of the bytes so far (0 for an empty message), data is a
    bytes-like chunk. zlib.crc32(b, crc32(a)) == crc32(a + b), so chunks chain for free."""
    return zlib.crc32(data, crc)


class Crc32:
    """Incremental CRC for the per-byte contract (crc32_new/clear/update): one object per chandle."""

    def __init__(self):
        self.crc = 0                           # CRC of the empty message

    def clear(self):
        self.crc = 0

    def update(self, b):
        self.crc = zlib.crc32(bytes((b,)), self.crc)
        return self.crc                        # same as the DUT's crc output after this byte


# ---------------------------------------------------------------- FIR (fir8.sv)
class Fir8:
    """Bit-exact model of fir8.sv: Q1.15, 35-bit accumulator, round half-up, saturate to int16.
    One instance per DUT instance; SV holds it as a chandle (a PyObject* owned by the C bridge)."""
    live = 0                                   # instances alive (proves chandle refcounting)

    def __init__(self, coef):
        self.c = np.asarray(coef, dtype=np.int64)          # for block() (numpy)
        self.cl = [int(v) for v in coef]                     # for step() (plain ints)
        assert len(self.cl) == 8
        self.h = [0] * 7                                     # x[n-1] .. x[n-7], newest first
        Fir8.live += 1

    def __del__(self):
        Fir8.live -= 1

    def _out(self, acc):
        if "fir_trunc" in BUG:                 # injected bug: truncate instead of round
            r = acc >> 15
        else:
            r = (acc + (1 << 14)) >> 15        # >> on Python int / numpy int64 is arithmetic (floor), like SV >>>
        return min(32767, max(-32768, r)) if isinstance(acc, int) else np.clip(r, -32768, 32767)

    def step(self, x):
        """One sample in, one sample out (per-sample DPI call). Plain Python ints: for 8 numbers,
        numpy's per-call overhead costs more than the arithmetic (see step_np and the lab)."""
        c, h = self.cl, self.h
        acc = c[0] * x + c[1] * h[0] + c[2] * h[1] + c[3] * h[2] + c[4] * h[3] + c[5] * h[4] + c[6] * h[5] + c[7] * h[6]
        self.h = [x] + h[:6]
        return self._out(acc)

    def step_np(self, x):
        """Same as step() written 'the numpy way'. Correct, and much slower per sample."""
        hist = np.array(self.h, dtype=np.int64)
        acc = int(self.c[0]) * x + int(np.dot(self.c[1:], hist))
        hist = np.roll(hist, 1)
        hist[0] = x
        self.h = hist.tolist()
        return int(self._out(np.int64(acc)))

    def block(self, xin, yout):
        """Batch: xin/yout are writable buffers of int16 (zero-copy views of SV arrays)."""
        x = np.frombuffer(xin, dtype=np.int16).astype(np.int64)
        if "keep_memoryview" in BUG:           # injected bug: keep the memoryview itself (the bridge detects it)
            self.kept = xin
        if "keep_numpy" in BUG:                # injected bug: keep a numpy view (the bridge cannot detect it)
            global KEPT
            KEPT = np.frombuffer(xin, dtype=np.int16)
        full = np.concatenate([np.array(self.h[::-1], dtype=np.int64), x])   # oldest .. newest
        acc = np.convolve(full, self.c, mode="valid")        # len(x) outputs, exact in int64
        np.frombuffer(yout, dtype=np.int16)[:] = self._out(acc)
        self.h = full[::-1][:7].tolist()
        return len(x)


# ---------------------------------------------------------------- wide integers
def mul_wide(a, b):
    """100 x 100 -> 200-bit product. Python ints are arbitrary precision: no carry handling."""
    return a * b


def fir_live(*_):
    return Fir8.live


def kept0(*_):
    """Element 0 of the numpy view kept by the keep_numpy bug, read OUTSIDE any DPI call."""
    return int(KEPT[0])


def nop(*_):
    return 0


def big(*_):
    return 1 << 70                             # does not fit a longint: OverflowError in the bridge


def fails(x):
    """Raises on purpose: exercises error propagation into the SV scoreboard."""
    return {"ok": 1}[x]


if __name__ == "__main__":                     # self-check, no simulator involved
    assert crc32_update(0, b"123456789") == 0xCBF43926
    assert crc32_update(crc32_update(0, b"12345"), b"6789") == 0xCBF43926
    c = Crc32()
    assert [c.update(b) for b in b"123456789"][-1] == 0xCBF43926
    coef = [0x4000, -0x2000, 0x1000, 0x7FFF, -0x8000, 0x0800, 1, -1]
    rng = np.random.default_rng(1)
    xs = rng.integers(-32768, 32768, 3000).astype(np.int16)
    a, b = Fir8(coef), Fir8(coef)
    ys = np.zeros(len(xs), np.int16)
    for i in range(0, len(xs), 512):                          # batch in uneven chunks
        b.block(xs[i:i + 512].tobytes(), memoryview(ys[i:i + 512]).cast("B"))
    assert [a.step(int(x)) for x in xs] == ys.tolist()
    d = Fir8(coef)
    assert [d.step_np(int(x)) for x in xs[:300]] == ys[:300].tolist()
    h, ref = [0] * 8, []                                      # plain-int reference, straight from fir8.sv
    for x in xs.tolist():
        h = [x] + h[:7]
        ref.append(max(-32768, min(32767, (sum(c * v for c, v in zip(coef, h)) + (1 << 14)) >> 15)))
    assert ref == ys.tolist()
    assert mul_wide((1 << 100) - 1, (1 << 100) - 1) < 1 << 200
    print("golden.py self-check OK")
