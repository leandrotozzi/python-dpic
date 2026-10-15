# legacy

Earlier experiments (2014 onward) that the [tutorial](../tutorial) grew out of. They target old
toolchains (Python 2.6, Cadence irun, CentOS 6) and are kept for reference only: not maintained,
not tested by CI. Step 07 of the tutorial explains what changed since.

| Folder | What |
|---|---|
| `dpic-examples/` | First DPI-C experiments: a counter model in C, static vs dynamic state |
| `python-embedded-C/` | Embedding CPython in C, then calling it through DPI from irun |
| `sockets_dpi/` | SV ↔ C over TCP sockets (a Fibonacci server). Chris Spear's example (2011), redistributed under its own notice in each file, not under this repo's MIT license |
| `bridge_irun/` | Jupyter notebook driving an interactive irun session |

## Third-party material

These used to be copied here; read them at the source instead:

- Martin C. Brown, *Embed Python scripting in C applications*, IBM developerWorks tutorial
  (2005). Author's note: <https://www.mcb.guru/2005/04/02/embed-python-scripting-in-c-applications/>.
  The current, maintained equivalent is the Python docs:
  [Embedding Python in Another Application](https://docs.python.org/3/extending/embedding.html).
- AMIQ Consulting, [How to Call C-functions from SystemVerilog Using DPI-C](https://www.consulting.amiq.com/2019/01/30/how-to-call-c-functions-from-systemverilog-using-dpi-c/)
  (2019): the SV ↔ C type-mapping example.
- AMIQ Consulting, [How to Connect SystemVerilog with Python](https://www.consulting.amiq.com/?p=5664)
  (2019): SV → DPI-C client → TCP → Python server.
