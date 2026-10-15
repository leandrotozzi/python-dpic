#!/bin/bash
# Step 05 lab: export, context, scopes, timed memory models. Logs in build/<name>.log, builds in build/<name>.build.
cd "$(dirname "$0")"
source ../../common/lab.sh
rm -f build/*.log

# batch 1: scopes and context rules
vlb scopes   scopes.sv scopes.c
vlb setscope setscope.sv setscope.c
vlb noctx    noctx.sv noctx.c
vlb stale    noctx.sv noctx.c -DSTALE
vlb xtask    xtask.sv xtask.c
vlb fn2task  fn2task.sv fn2task.c
wait
# batch 2: timing in exports (expected compile errors), pure/comb probes, cost
vlb xt_delay  xtime.sv xtime.c
vlb xt_at     xtime.sv xtime.c -DAT
vlb xt_nested xtime.sv xtime.c -DNESTED
vlb pure      pure.sv pure.c
vlb comb      comb.sv pure.c
vlb bench     bench.sv bench.c
vlb outarg    outarg.sv outarg.c
wait
# batch 3: memory models (book Samples 12.37–12.45)
vlb mem_func mem_func.sv mem_func.c
vlb mem_task mem_task.sv mem_task.c
vlb mem_oop  mem_oop.sv mem_oop.c
vlb mem_pull mem_pull.sv mem_pull.c
vlb sib      ex/static_init_bug.sv mem_pull.c
vlb pull1    ex/pull1.sv ex/pull1.c
wait
# batch 3b: time API (H.13), export restrictions and shared C names (35.4, 35.5.6)
vlb svtime   svtime.sv svtime.c
vlb xdyn     xdyn.sv
vlb xshared  xshared.sv xshared.c
wait
# batch 4: remaining exercise solutions
for e in ex12_8 ex12_10 predict report broadcast; do vlb $e ex/$e.sv ex/$e.c; done
wait

for e in scopes setscope noctx stale xtask fn2task pure comb bench outarg mem_func mem_oop mem_pull sib pull1 \
         ex12_8 ex12_10 predict broadcast svtime xshared; do
  vlr $e $e
done
vlr report report +verilator+error+limit+10
