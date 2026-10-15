#!/bin/bash
# Step 03 lab: static vs per-instance C state, chandle, C++ objects behind extern "C" wrappers.
cd "$(dirname "$0")"; source ../../common/lab.sh
rm -f build/*.log

vlb static   static_counter.sv static_counter.c
vlb chandle  chandle_counter.sv chandle_counter.c
vlb cpp      chandle_counter.sv counter7.cpp
vlb tlm      tlm.sv tlm.cpp
wait
vlr static   static
vlr static_reset static +hold_reset
vlr chandle  chandle
vlr cpp      cpp
vlr tlm      tlm

# expected failures and pitfalls
vlb booksig  chandle_counter.sv book_sig.c
vlb booksigh chandle_counter.sv book_sig.c -CFLAGS -DCHECK_PROTO
vlb nocxx    chandle_counter.sv nocxx.cpp
vlb nocxxh   chandle_counter.sv nocxx.cpp -CFLAGS -DCHECK_PROTO
vlb pure     pure_lie.sv pure_lie.c
vlb honest   pure_honest.sv pure_lie.c
wait
vlr booksig  booksig
vlr nocxxh   nocxxh
vlr pure     pure
vlr honest   honest

# thread experiment: which OS threads call pure / non-pure imports
vlb thr1     threads.sv threads.cpp
vlb thr2     threads.sv threads.cpp --threads 2
vlb thr2none threads.sv threads.cpp --threads 2 --threads-dpi none
vlb thr2all  threads.sv threads.cpp --threads 2 --threads-dpi all
wait
for b in thr1 thr2 thr2none thr2all; do vlr $b $b; done
vlr chandle_null chandle +null
vlr booksig_null booksig +null      # book's version has no null guard

# exercise solutions
vlb ex2      ex/shift_static.sv ex/shift_static.c
vlb ex345    ex/shift_inst.sv ex/shift.c
vlb ex6      ex/shift_class.sv ex/shift.c
vlb clone    ex/clone.sv ex/clone.cpp
wait
vlb fifo     ex/fifo_model.sv ex/fifo_model.cpp
vlb registry ex/registry.sv ex/registry.cpp
wait
for b in ex2 ex345 ex6 clone fifo registry; do vlr $b $b; done

# chandle rules from IEEE 1800-2023 6.14: what Verilator rejects, warns about, or accepts
for f in neg/chandle_rule*.sv; do
  n=$(basename $f .sv)
  ( verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSED -Wno-UNDRIVEN $f > build/$n.lint 2>&1; echo "rc=$?" >> build/$n.lint ) &
done
wait
