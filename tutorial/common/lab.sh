# Shared helpers for every lab's run.sh.  Usage inside lab/run.sh:
#   cd "$(dirname "$0")"; source ../../common/lab.sh
#   vlb hello  hello.sv hello.c            # build in background -> build/hello.build, binary build/vl_hello/Vtop
#   vlb pyx    pyx.sv pyx.c $(py_flags)    # same, linking an embedded Python interpreter
#   wait
#   vlr hello  hello                       # run -> build/hello.log (plusargs may follow)
# Every testbench's top module is called `top`. Logs use `LOG <tag> k=v ...` lines that check.py parses.
mkdir -p build
command -v ccache > /dev/null && export OBJCACHE=ccache   # reuse Verilator runtime objects across builds
COMMON="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VL="verilator --binary -j 2 --timing --assert -Wno-fatal -Wno-lint -Wno-style --top-module top"

vlb() {  # vlb <name> <files and extra verilator args...>
  local n=$1; shift
  ( $VL -Mdir build/vl_$n "$@" > build/$n.build 2>&1 || echo "BUILD_FAIL" >> build/$n.build ) &
}
vlr() {  # vlr <log-name> <build-name> [plusargs...]
  local log=$1 bin=$2; shift 2
  if [ -x build/vl_$bin/Vtop ]; then ./build/vl_$bin/Vtop "$@" > build/$log.log 2>&1 || echo "RUN_RC=$?" >> build/$log.log
  else echo "BUILD_OR_RUN_FAIL" > build/$log.log; fi
}
py_flags() {  # compiler/linker flags to embed the python3 found on PATH (one -CFLAGS/-LDFLAGS per word)
  local f
  for f in $(python3-config --includes); do echo -n "-CFLAGS $f "; done
  for f in $(python3-config --embed --ldflags); do echo -n "-LDFLAGS $f "; done
}
