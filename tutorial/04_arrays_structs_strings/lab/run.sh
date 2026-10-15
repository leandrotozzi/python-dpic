#!/bin/bash
# Step 04 lab: arrays, open arrays, structs, strings across DPI-C.  cd lab && ./run.sh
cd "$(dirname "$0")"
source ../../common/lab.sh
rm -f build/*.log
vlb fib fib.sv fib.c
vlb openarr openarr.sv openarr.c
vlb packed packed.sv packed.c
vlb structs structs.sv structs.c
vlb s_ups structs.sv structs.c -DUNPACKED -CFLAGS -DUNPACKED_C
vlb strings strings.sv strings.c
vlb ex ex/ex.sv ex/ex.c
vlb bug_loop ex/bug_loop.sv ex/bug_loop.c
rm -rf build/vl_bug_str    # always recompile: we want the compiler warning in the log
vlb bug_str ex/bug_str.sv ex/bug_str.c
vlb outdir outdir.sv outdir.c
vlb k_fix  kinds.sv kinds.c
vlb k_dyn  kinds.sv kinds.c -DDYN
vlb k_que  kinds.sv kinds.c -DQUE
vlb k_slice kinds.sv kinds.c -DSLICE
wait
vlr fib fib
vlr openarr openarr
vlr k_fix k_fix
vlr packed packed
vlr strings strings
vlr outdir outdir
vlr ex ex
vlr bug_loop bug_loop
vlr structs structs
vlr s_ups s_ups
