`timescale 1ns/1ps
// Model throughput, no DUT: the cost of the model + the DPI crossing, per backend.
// Same source for both backends (step 06's contract); +define+PY_BACKEND adds Python-only measurements.
module top;
  import golden_pkg::*;
  import "DPI-C" function real wall_s();                         // 06's wall.c
`ifdef PY_BACKEND
  import py_extra_pkg::*;
  longint none[1] = '{0};
`endif
  localparam int NS = 100000, BLK = 1024;
  shortint coef[8] = '{16'sh4000, -16'sh2000, 16'sh1000, 16'sh7fff, -16'sh8000, 16'sh0800, 16'sh0001, -16'sh0001};
  shortint xs[BLK], ys[BLK];
  byte unsigned buf_[BLK];
  chandle h, hc;
  real t;
  int unsigned c;

  function automatic longint rate(longint items, real s);       // items per second
    return longint'(items / (s > 0 ? s : 1e-9));
  endfunction

  initial begin
    foreach (xs[i]) xs[i] = shortint'($urandom);
    foreach (buf_[i]) buf_[i] = 8'($urandom);
    t = wall_s(); h = fir8_new(coef);                            // first call: interpreter + numpy import
    $display("LOG perf first_call_us=%0d", longint'((wall_s() - t) * 1e6));
    hc = crc32_new();
    t = wall_s();
    for (int i = 0; i < NS; i++) void'(fir8_step(h, xs[i % BLK]));
    $display("LOG perf fir_step_per_s=%0d", rate(NS, wall_s() - t));
    t = wall_s();
    for (int i = 0; i < NS / BLK; i++) fir8_block(h, xs, ys, BLK);
    $display("LOG perf fir_block_samples_per_s=%0d", rate(NS / BLK * BLK, wall_s() - t));
    t = wall_s();
    for (int i = 0; i < NS; i++) c = crc32_update(hc, buf_[i % BLK]);
    $display("LOG perf crc_byte_calls_per_s=%0d", rate(NS, wall_s() - t));
    t = wall_s();
    for (int i = 0; i < NS / BLK; i++) c = crc32_msg(buf_, BLK);
    $display("LOG perf crc_block_bytes_per_s=%0d", rate(NS / BLK * BLK, wall_s() - t));
`ifdef PY_BACKEND
    t = wall_s();
    for (int i = 0; i < NS; i++) void'(py_call_i64("golden", "nop", none));
    $display("LOG perf py_nop_calls_per_s=%0d", rate(NS, wall_s() - t));
    t = wall_s();                                                // book §12.9: a new process per call
    for (int i = 0; i < 5; i++) void'($system("python3 -c 'import zlib; zlib.crc32(b\"x\")'"));
    $display("LOG perf system_python_calls_per_s=%0d", rate(5, wall_s() - t));
    $display("LOG perf done err=%s", py_last_error());
`endif
    fir8_free(h);
    crc32_free(hc);
    $finish;
  end
endmodule
