#!/bin/bash
# Step 07 lab: embedding CPython in a Verilator simulation through DPI-C.
cd "$(dirname "$0")"; source ../../common/lab.sh
rm -f build/*.log
vlb basic     basic.sv basic.c $(py_flags)
# without --embed, python3-config --ldflags omits -lpython3.X (since Python 3.8): link must fail
NOEMBED=$(for f in $(python3-config --includes); do echo -n "-CFLAGS $f "; done; for f in $(python3-config --ldflags); do echo -n "-LDFLAGS $f "; done)
vlb noembed   basic.sv basic.c $NOEMBED
vlb lifecycle lifecycle.sv lifecycle.c $(py_flags)
vlb buffering buffering.sv buffering.c $(py_flags)
vlb errors    errors.sv errors.c $(py_flags)
vlb config    config.sv config.c $(py_flags)
wait
vlb th_single    threads.sv threads.c $(py_flags)
vlb th_np        threads.sv threads.c $(py_flags) --threads 4
vlb th_np_safe   threads.sv threads.c $(py_flags) --threads 4 -CFLAGS -DGIL_SAFE
vlb th_pure      threads.sv threads.c $(py_flags) --threads 4 +define+PURE
vlb th_pure_safe threads.sv threads.c $(py_flags) --threads 4 +define+PURE -CFLAGS -DGIL_SAFE
vlb th_all_safe  threads.sv threads.c $(py_flags) --threads 4 --threads-dpi all -CFLAGS -DGIL_SAFE
wait
for e in shift shifter eval lazy spawn; do vlb ex_$e ex/$e.sv ex/$e.c $(py_flags); done
[ -x build/venv/bin/python ] || python3 -m venv --without-pip build/venv
[ -x build/venv_sys/bin/python ] || python3 -m venv --without-pip --system-site-packages build/venv_sys
wait
vlr basic basic +pydir=py
for m in fin nofin guard raw cycle; do vlr life_$m lifecycle +mode=$m; done
vlr buf_none  buffering
vlr buf_py    buffering +pyflush=1
vlr buf_both  buffering +pyflush=1 +cflush=1
vlr buf_unbuf buffering +unbuffered=1 +cflush=1
vlr errors errors
vlr cfg_sys      config +api=config
vlr cfg_venv     config +api=config +venv=$PWD/build/venv/bin/python
vlr cfg_init     config +api=initconfig
vlr cfg_initvenv config +api=initconfig +venv=$PWD/build/venv/bin/python
vlr cfg_replace  config +api=config +replace_path=1
for t in th_single th_np th_np_safe th_pure th_pure_safe th_all_safe; do vlr $t $t; done
vlr cfg_venv_sys config +api=config +venv=$PWD/build/venv_sys/bin/python
for e in shift shifter eval spawn; do vlr ex_$e ex_$e; done
PY_DPI_PATH=py vlr ex_lazy ex_lazy
vlr ex_eval_limit ex_eval +verilator+error+limit+10
