#!/bin/bash
# Step 01 lab: build and run every experiment. Logs in build/<name>.build (compile) and build/<name>.log (run).
cd "$(dirname "$0")"
source ../../common/lab.sh
rm -f build/*.log build/*.build

vlb hello     hello.sv hello.c
vlb hdr       hello.sv hdr.c
vlb noextern  hello.sv noextern.c
vlb missing   hello.sv missing.c
vlb mismatch  mismatch.sv mismatch.c
vlb mmhdr     mismatch.sv mismatch_hdr.c
vlb pure      pure.sv pure.c
vlb keyword   keyword.sv
vlb mmhdr2    mismatch.sv mismatch_hdr2.c
vlb legacy    legacy.sv hello.c
vlb dup       dup.sv
vlb pkg       pkg.sv pkg.c
vlb comb      comb.sv pure.c
vlb ref       ref.sv
wait
# LRM rules for pure and for shared C names (35.5.2, 35.4, 35.5.4)
vlb pr_out    pure_rules.sv pure_rules.c
vlb pr_void   pure_rules.sv pure_rules.c -DVOID
vlb pr_task   pure_rules.sv pure_rules.c -DTASK
vlb cid       cid.sv cid.c
vlb cid_bad   cid.sv cid.c -DBAD
wait
for n in pr_out pr_void pr_task cid; do vlr $n $n; done
vlr hello    hello
vlr hdr      hdr
vlr mismatch mismatch
vlr pure     pure
vlr legacy   legacy
vlr pkg      pkg
vlr comb     comb

# --- exercise solutions (lab/ex)
vlb ex1   ex/ex1_shift.sv ex/ex1_shift.c
vlb ex2   ex/ex2_fact64.sv ex/ex2_fact64.c
vlb ex5   ex/ex5_strlen.sv
vlb ex6   ex/ex6_gcd.sv ex/ex6_gcd.c
vlb ex7   ex/ex7_db.sv
vlb ex5f  ex/ex5_fix.sv ex/ex5_fix.c
vlb ex11  ex/ex11_popcount.sv ex/ex11_popcount.c
vlb ex12  hello.sv ex/ex12_static.c
wait
for n in ex1 ex2 ex5f ex6 ex7 ex11; do vlr $n $n; done
