#!/bin/bash
# Step 08 lab: Python golden models over DPI. Step 06's contract (golden_pkg.sv), two backends:
# 06's golden.c (C) and this step's golden_py.c (Python). Same testbench sources for both.
cd "$(dirname "$0")"
source ../../common/lab.sh
export PYTHONPATH="$PWD:$PWD/ex"          # the embedded interpreter finds golden.py (and ex/ex_models.py) here
RTL=../../common/rtl
G6=../../06_golden_model_c/lab            # the shared contract and the C backend live in step 06
rm -f build/*.log

PKG="$G6/golden_pkg.sv"
PY="$PKG py_extra_pkg.sv golden_py.c $G6/wall.c $(py_flags)"
C="$PKG $G6/golden.c $G6/wall.c"
EX="$PKG py_extra_pkg.sv ex/golden_ex.c $(py_flags)"
vlb crc_py    $PY $RTL/crc32_stream.sv tb_crc.sv
vlb crc_c     $C  $RTL/crc32_stream.sv tb_crc.sv
vlb fir_py    $PY $RTL/fir8.sv tb_fir.sv
vlb fir_c     $C  $RTL/fir8.sv tb_fir.sv
wait
vlb fir_c_bug $C  $RTL/fir8.sv tb_fir.sv -CFLAGS -DMUTANT=1      # 06's mutant 1 = round by truncation
vlb wide_py   $PY tb_wide.sv
vlb err_py    $PY tb_err.sv
vlb perf_py   $PY tb_perf.sv +define+PY_BACKEND
vlb perf_c    $C  tb_perf.sv
wait
vlb crc_static  $PY $RTL/crc32_stream.sv tb_crc.sv +define+STATIC_BUG
vlb dyn_fail    $C tb_dyn_fail.sv
vlb shape_fail  $C tb_shape_fail.sv
vlb port_fail   $RTL/fir8.sv tb_port_fail.sv
verilator --lint-only pragma_fail.sv > build/pragma_fail.build 2>&1
wait
vlb ex_shift      $PY ex/ex_shift.sv
vlb ex_shiftreg   $EX ex/ex_shiftreg.sv
vlb ex_signed     $EX ex/ex_signed.sv
vlb ex_crc_frames $PY $RTL/crc32_stream.sv ex/ex_crc_frames.sv
vlb ex_lpf        $EX $RTL/fir8.sv ex/ex_lpf.sv
wait

vlr crc_py        crc_py
vlr crc_py_byte   crc_py +per_byte
vlr crc_c         crc_c
vlr crc_c_byte    crc_c  +per_byte
vlr fir_py        fir_py
vlr fir_py_block  fir_py +block
GOLDEN_BUG=fir_trunc vlr fir_py_bug    fir_py              # same binary, the model reads the environment
GOLDEN_BUG=fir_trunc vlr fir_py_bugblk fir_py +block
vlr fir_c         fir_c
vlr fir_c_block   fir_c  +block
vlr fir_c_bug     fir_c_bug
vlr wide_py       wide_py
vlr err_py        err_py
vlr err_py_lim    err_py +verilator+error+limit+10
vlr perf_py       perf_py
vlr perf_c        perf_c
vlr crc_static    crc_static
vlr ex_shift      ex_shift
vlr ex_shiftreg   ex_shiftreg
vlr ex_signed     ex_signed
vlr ex_crc_frames ex_crc_frames
vlr ex_lpf        ex_lpf
vlr ex_lpf_noreset ex_lpf +no_model_reset
grep -h -E "^(LOG|PASS|FAIL|MISMATCH)" build/*.log > build/results.txt
