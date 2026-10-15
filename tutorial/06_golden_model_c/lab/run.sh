#!/bin/bash
# Step 06 lab: the DUTs in ../../common/rtl checked against the C golden models in golden.c.
# Writes build/<name>.log; check.py asserts on them.        cd lab && ./run.sh   (~1-2 min)
cd "$(dirname "$0")"; source ../../common/lab.sh
R=../../common/rtl
rm -f build/*.log
FIR="golden_pkg.sv $R/fir8.sv fir_tb.sv wall.c"
CRC="golden_pkg.sv $R/crc32_stream.sv crc_tb.sv"

# --- builds (background, then wait)
vlb fir     $FIR golden.c
vlb crc     $CRC golden.c
vlb bench   golden_pkg.sv bench.sv golden.c wall.c bench.c
vlb fir_m1  $FIR golden.c -CFLAGS -DMUTANT=1
vlb fir_m2  $FIR golden.c -CFLAGS -DMUTANT=2
vlb fir_m4  $FIR golden.c -CFLAGS -DMUTANT=4
wait
vlb crc_m3  $CRC golden.c -CFLAGS -DMUTANT=3
vlb fir_cpp $FIR ex/golden_cpp.cpp
vlb shift   ex/shift_tb.sv ex/shift.c
vlb residue golden_pkg.sv ex/residue_tb.sv golden.c
vlb len     golden_pkg.sv ex/len_tb.sv golden.c
vlb dup     $FIR golden.c ex/golden_cpp.cpp           # exercise 11: expected to fail at link
grep -v 'Vtop__Dpi.h' ex/golden_cpp.cpp > build/golden_cpp_nohdr.cpp
vlb nohdr   $FIR build/golden_cpp_nohdr.cpp            # exercise 9: no header -> C++ names -> link fails
wait

# --- runs (in parallel: the randomize() ones spend most of their time waiting on the solver)
vlr bench        bench +N=10000000                    # first and alone: it measures time
vlr fir_s1       fir   +SEED=1 +N=500 &
vlr fir_b1       fir   +SEED=1 +N=500 +MODE=batch &
vlr fir_s2       fir   +SEED=2 +N=500 &
vlr fir_flip     fir   +SEED=1 +FAST +N=2000 +FLIP=100 &
vlr fir_flip_b   fir   +SEED=1 +FAST +N=2000 +FLIP=100 +MODE=batch &
vlr crc_s1       crc   +SEED=1 +MSGS=12 &
vlr crc_b1       crc   +SEED=1 +MSGS=12 +MODE=batch &
vlr crc_flip     crc   +SEED=1 +MSGS=12 +FLIP=500 &
vlr crc_flip_b   crc   +SEED=1 +MSGS=12 +FLIP=500 +MODE=batch &
vlr crc_m3       crc_m3 +SEED=1 +MSGS=12 &
vlr crc_m3_b     crc_m3 +SEED=1 +MSGS=12 +MODE=batch &
wait
vlr fir_fast_s   fir   +SEED=3 +FAST +N=200000              # timed: run alone
vlr fir_fast_b   fir   +SEED=3 +FAST +N=200000 +MODE=batch
vlr fir_m1       fir_m1 +SEED=3 +FAST +N=20000 &
vlr fir_m2       fir_m2 +SEED=3 +FAST +N=20000 &
vlr fir_m4       fir_m4 +SEED=3 +FAST +N=20000 &
vlr fir_cpp      fir_cpp +SEED=3 +FAST +N=20000 &
vlr fir_c_ref    fir    +SEED=3 +FAST +N=20000 &
vlr shift        shift &
vlr residue      residue &
vlr len          len &
wait
grep -h "^PASS\|^FAIL" build/*.log | sort | uniq -c > build/results.txt
