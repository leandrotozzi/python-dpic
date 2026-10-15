"""Toy Python functions called from SystemVerilog through DPI-C (step 07)."""
import math
import sys


def add(a, b):
    return a + b


def hypot(x, y):
    return math.hypot(x, y)


def reverse(s):
    return s[::-1]


def checksum(data):
    """16-bit sum of a bytes object."""
    return sum(data) & 0xFFFF


def divide(a, b):
    return a // b            # b == 0 raises ZeroDivisionError


def shout(msg):
    print(f"py: {msg}")      # no flush on purpose: see the buffering experiment


def whoami():
    return f"python {sys.version.split()[0]} prefix={sys.prefix}"
