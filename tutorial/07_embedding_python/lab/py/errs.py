"""Functions that fail, for the error-handling and refcount experiments."""
import sys


def divide(a, b):
    return _inner(a, b)


def _inner(a, b):
    return a // b                      # ZeroDivisionError when b == 0


def make():
    return [0] * 1000                  # a fresh object every call


def blocks():
    return sys.getallocatedblocks()
