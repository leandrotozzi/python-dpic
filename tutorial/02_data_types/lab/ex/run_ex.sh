# Exercise solutions (sourced by ../run.sh, which already sourced common/lab.sh).
vlb ex_shift    ex/shift.sv    ex/shift.c
vlb ex_popcount ex/popcount.sv ex/popcount.c
vlb ex_sext     ex/sext.sv     ex/sext.c
vlb ex_partsel  ex/partsel_fix.sv ex/partsel_fix.c
wait
vlb ex_isneg    ex/isneg.sv    ex/isneg.c
vlb ex_isneg_u  ex/isneg.sv    ex/isneg.c -CFLAGS -funsigned-char
vlb ex_mul128   ex/mul128.sv   ex/mul128.c
vlb ex_xz       ex/xz.sv       ex/xz.c
vlb ex_c4fix    counter4.sv    ex/counter4_fix.c
wait
for t in ex_shift ex_popcount ex_sext ex_partsel ex_isneg ex_isneg_u ex_mul128 ex_xz ex_c4fix; do vlr $t $t; done
verilator --cc -Wno-fatal --top-module top -Mdir build/ex_protos ex/protos.sv > /dev/null 2>&1
grep -h "extern" build/ex_protos/Vtop__Dpi.h > build/ex_protos.h
cc -DUNIT -I"$(verilator --getenv VERILATOR_ROOT)/include/vltstd" ex/xz.c -o build/xz_unit && ./build/xz_unit > build/ex_xz_unit.log
