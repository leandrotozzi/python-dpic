// The SV-side contract of the golden models. Step 08 reuses this file unchanged:
// only the C/C++ object that implements these symbols changes (C here, Python there).
package golden_pkg;
  // ---- CRC-32/IEEE: incremental (one call per byte, state behind a chandle) ----
  import "DPI-C" function chandle      crc32_new();
  import "DPI-C" function void         crc32_free  (input chandle h);
  import "DPI-C" function void         crc32_clear (input chandle h);
  import "DPI-C" function int unsigned crc32_update(input chandle h, input byte unsigned b);
  // ---- CRC-32/IEEE: whole message (stateless, open array) ----
  // The actual must be a FIXED-size array (Verilator 5.052 rejects dynamic arrays and queues
  // as DPI arguments), so the length travels separately: CRC of msg[0..len-1].
  import "DPI-C" pure function int unsigned crc32_msg(input byte unsigned msg[], input int len);

  // ---- 8-tap Q1.15 FIR: stateful, per-sample or per-block ----
  import "DPI-C" function chandle  fir8_new  (input shortint coef[8]);
  import "DPI-C" function void     fir8_free (input chandle h);
  import "DPI-C" function shortint fir8_step (input chandle h, input shortint x);
  // y[i] = fir8_step(h, x[i]) for i in 0..n-1 (fixed-size buffers, n <= their size)
  import "DPI-C" function void     fir8_block(input chandle h, input shortint x[], output shortint y[],
                                              input int n);
endpackage
