#!/bin/bash
# Step 02 lab: SV <-> C data types through DPI-C, measured on Verilator.
# Writes build/<name>.build (compiler output) and build/<name>.log (simulation output).
cd "$(dirname "$0")"
source ../../common/lab.sh
rm -rf build/*          # full rebuild: Verilator skips warnings on an up-to-date Mdir

vlb types       types.sv types.c
vlb types_hdr   types.sv types.c -CFLAGS -DDPI_HDR                   # expected: C++ compile error (shortreal)
vlb types_fix   types.sv types.c -CFLAGS -DSREAL_FIX
vlb types_uchar types.sv types.c -CFLAGS -funsigned-char             # plain char unsigned, like ARM Linux
wait
vlb vec      vec.sv vec.c
vlb dir      dir.sv dir.c
vlb counter4 counter4.sv counter4.c
vlb zlit     zlit.sv types.c                                         # expected: Verilator error (1'bz argument)
wait
for t in types types_fix types_uchar vec dir counter4; do vlr $t $t; done

# return types and argument prototypes: elaborate only, keep the generated header / the error
mkdir -p build/proto
proto() {  # proto <name> <sv declaration...>
  local n=$1; shift
  printf '%s\nmodule top; endmodule\n' "$*" > build/proto/$n.sv
  verilator --cc -Wno-fatal --top-module top -Mdir build/proto/$n build/proto/$n.sv > build/proto/$n.out 2>&1
  grep -h "extern" build/proto/$n/Vtop__Dpi.h >> build/proto/$n.out 2>/dev/null
}
proto r_bit32   'import "DPI-C" function bit [31:0] f();'
proto r_bit33   'import "DPI-C" function bit [32:0] f();'
proto r_logic7  'import "DPI-C" function logic [6:0] f();'
proto r_logic   'import "DPI-C" function logic f();'
proto r_integer 'import "DPI-C" function integer f();'
proto r_string  'import "DPI-C" function string f();'
proto a_integer 'import "DPI-C" function void f(input integer a);'
proto a_time    'import "DPI-C" function void f(input time a);'
proto a_logic1  'import "DPI-C" function void f(input logic [0:0] a);'
proto a_ostring 'import "DPI-C" function void f(output string a);'
proto a_ref     'import "DPI-C" function void f(ref int a);'
proto a_sreal   'import "DPI-C" function void f(input shortreal a, output shortreal b);'

# exercise solutions
source ex/run_ex.sh
