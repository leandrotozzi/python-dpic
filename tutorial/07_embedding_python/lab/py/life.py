"""Helpers for the lifecycle and buffering experiments."""
import atexit


def say(msg, flush=False):
    print(f"PY {msg}", flush=flush)


atexit.register(lambda: print("PY atexit handler ran", flush=True))
