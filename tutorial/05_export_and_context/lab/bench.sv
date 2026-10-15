`timescale 1ns/1ns
// Cost per call: plain import vs pure vs context, and a C->SV export round trip.
module top;
  import "DPI-C"         function int f_gen(int x);
  import "DPI-C" pure    function int f_pure(int x);
  import "DPI-C" context function int f_ctx(int x);
  import "DPI-C" context function int f_ctx_export(int x);   // calls sv_inc() once per call
  import "DPI-C"         function longint now_ns();
  export "DPI-C" function sv_inc;
  function int sv_inc(int x); return x + 1; endfunction
  localparam int N = 5_000_000;
  longint t0;
  int acc;
  initial begin
    t0 = now_ns(); for (int i = 0; i < N; i++) acc += f_gen(i);
    $display("LOG bench kind=gen ns_per_call=%0.2f", real'(now_ns() - t0) / N);
    t0 = now_ns(); for (int i = 0; i < N; i++) acc += f_pure(i);
    $display("LOG bench kind=pure ns_per_call=%0.2f", real'(now_ns() - t0) / N);
    t0 = now_ns(); for (int i = 0; i < N; i++) acc += f_ctx(i);
    $display("LOG bench kind=context ns_per_call=%0.2f", real'(now_ns() - t0) / N);
    t0 = now_ns(); for (int i = 0; i < N; i++) acc += f_ctx_export(i);
    $display("LOG bench kind=context+export ns_per_call=%0.2f", real'(now_ns() - t0) / N);
    $display("LOG bench acc=%0d", acc);
    $finish;
  end
endmodule
