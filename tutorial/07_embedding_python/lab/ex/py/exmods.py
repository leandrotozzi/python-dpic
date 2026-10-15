"""Python side of the step 07 exercise solutions."""
MASK = 0xFFFF_FFFF


def shift_naive(i, n):
    return (i << n) & MASK              # n < 0 raises ValueError: negative shift count


def shift(i, n):
    """Ex. 12.1 in Python: n > 0 shifts left, n < 0 shifts right, 32-bit result."""
    i &= MASK
    return (i << n) & MASK if n >= 0 else i >> -n


class Shifter:
    """Ex. 12.2-12.6: a 32-bit shift register with per-instance state and a shared call counter."""
    calls = 0                           # class attribute: shared by every instance (Ex. 12.4)

    def __init__(self, init=0):         # Ex. 12.5: initial value at instantiation
        self.reg = init & MASK

    def step(self, i, n, ld):
        Shifter.calls += 1
        self.reg = shift(i if ld else self.reg, n)
        return self.reg
