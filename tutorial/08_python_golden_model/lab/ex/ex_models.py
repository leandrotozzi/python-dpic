"""Exercise solutions: Python side."""
import golden

M32 = (1 << 32) - 1


def shift(i, n):
    """Ex. 12.1: shift a 32-bit unsigned value left (n > 0) or right (n < 0)."""
    return (i << n) & M32 if n >= 0 else (i & M32) >> -n


class Shift:
    """Ex. 12.2/12.3/12.5/12.6: a 32-bit shift register with load, one object per instance."""
    calls = 0                                  # Ex. 12.4: total calls across all instances

    def __init__(self, init=0):
        self.reg = init & M32                  # Ex. 12.5: initial value at instantiation

    def shift(self, i, n, ld):
        Shift.calls += 1
        self.reg = shift(i if ld else self.reg, n)
        return self.reg

    def total_calls(self, *_):                 # *_: see Fir8R.reset
        return Shift.calls


def wrap(v, bits):
    """Two's-complement wrap of a Python int to a signed `bits`-bit value (what SV arithmetic does)."""
    return ((v + (1 << (bits - 1))) % (1 << bits)) - (1 << (bits - 1))


def neg100(a):
    return wrap(-a, 100)                       # -(-2**99) wraps to -2**99, like SV


class Fir8R(golden.Fir8):
    """golden.Fir8 plus reset(), built from 8 scalar args so the generic py_new() can construct it."""

    def __init__(self, *coef):
        super().__init__(coef)

    def reset(self, *_):                       # *_: the generic bridge always passes >= 1 arg
        self.h = [0] * 7
        return 0
