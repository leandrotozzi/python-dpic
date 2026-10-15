// Cost per DPI call: empty call, golden-model calls (per item vs per block), and the same models
// written in plain SV for comparison. Prints `LOG bench name=... n=... ns_per_item=... mitems_s=...`.
`timescale 1ns/1ps
module top;
  import golden_pkg::*;
  import "DPI-C" function real wall_s();
  import "DPI-C" function int dpi_nop(input int x);

  localparam int BLK = 256;
  real t0;
  longint unsigned sink;                                 // keeps the compiler from deleting work

  task automatic report(string name, int n);
    real dt = wall_s() - t0;
    $display("LOG bench name=%0s n=%0d ns_per_item=%0.1f mitems_s=%0.2f", name, n, dt * 1e9 / n, n / dt / 1e6);
  endtask

  function automatic int sv_nop(int x); return x + 1; endfunction

  // the FIR in plain SV (same math as golden.c), as a class to keep state like the C model
  class sv_fir;
    shortint c[8], d[8];
    function shortint step(shortint x);
      longint acc = c[0] * x, r;
      for (int k = 1; k < 8; k++) acc += c[k] * d[k-1];
      r = (acc + 16384) >>> 15;
      for (int k = 7; k > 0; k--) d[k] = d[k-1];
      d[0] = x;
      return r > 32767 ? 32767 : r < -32768 ? -32768 : shortint'(r);
    endfunction
  endclass

  function automatic int unsigned sv_crc_byte(int unsigned s, byte unsigned b);
    s ^= b;
    for (int k = 0; k < 8; k++) s = s[0] ? (s >> 1) ^ 32'hEDB88320 : s >> 1;
    return s;
  endfunction

  initial begin
    int n = 2_000_000;
    shortint coef[8] = '{8192, -4096, 2048, 32767, -32768, 1024, 1, -1};
    shortint xb[BLK], yb[BLK];
    byte unsigned mb[BLK];
    chandle f, c;
    sv_fir s = new();
    int unsigned st;
    void'($value$plusargs("N=%d", n));
    foreach (xb[i]) begin xb[i] = shortint'(i * 2654435761); mb[i] = byte'(i * 40503); end

    t0 = wall_s(); for (int i = 0; i < n; i++) sink += sv_nop(i);    report("sv_nop", n);
    t0 = wall_s(); for (int i = 0; i < n; i++) sink += dpi_nop(i);   report("dpi_nop", n);

    f = fir8_new(coef);
    t0 = wall_s(); for (int i = 0; i < n; i++) sink += fir8_step(f, xb[i % BLK]); report("fir8_step", n);
    t0 = wall_s();
    for (int i = 0; i < n; i += BLK) begin fir8_block(f, xb, yb, BLK); sink += yb[0]; end
    report("fir8_block256", n);
    s.c = coef;
    t0 = wall_s(); for (int i = 0; i < n; i++) sink += s.step(xb[i % BLK]); report("sv_fir_step", n);

    c = crc32_new();
    t0 = wall_s(); for (int i = 0; i < n; i++) sink += crc32_update(c, mb[i % BLK]); report("crc32_update", n);
    t0 = wall_s(); for (int i = 0; i < n; i += BLK) sink += crc32_msg(mb, BLK);    report("crc32_msg256", n);
    st = '1;
    t0 = wall_s(); for (int i = 0; i < n; i++) st = sv_crc_byte(st, mb[i % BLK]);  report("sv_crc_byte", n);
    $display("LOG bench sink=%0d st=%h", sink, st);
    fir8_free(f); crc32_free(c);
    $finish;
  end
endmodule
