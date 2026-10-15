// Exercise solutions for step 04 (one testbench, one section per exercise).
typedef struct packed { bit [47:0] dst, src; bit [15:0] etype; } eth_hdr_t;
import "DPI-C" function longint ex1_sum(input int a[]);
import "DPI-C" function void    ex2_query(input bit [7:0] m[][], output int q[12]);
import "DPI-C" function void    ex5_hist(input byte data[], output int hist[]);
import "DPI-C" function void    ex7_swap_macs(inout eth_hdr_t h);
import "DPI-C" function int     ex9_sum_n(input int chunk[256], input int n);
import "DPI-C" function int     ex10_matmul(input int a[][], input int b[][], output int c[][]);
import "DPI-C" function void    ex11_xor(input bit [127:0] w[], output bit [127:0] x);
import "DPI-C" function void    ex12_shift_all(inout int unsigned v[], input int n);

module top;
  // Exercise 9: Verilator rejects dynamic arrays as open-array actuals -> chunk through a fixed buffer
  function automatic longint sum_dyn(const ref int d[]);
    int chunk[256];
    longint s = 0;
    for (int base = 0; base < d.size(); base += 256) begin
      int n = (d.size() - base < 256) ? d.size() - base : 256;
      for (int k = 0; k < n; k++) chunk[k] = d[base + k];
      s += ex9_sum_n(chunk, n);
    end
    return s;
  endfunction

  int a10[10:1], a37[3:7];
  bit [7:0] m[2:5][3:0];
  int q[12];
  byte data[64];
  int hist[16], ref_hist[16];
  eth_hdr_t h;
  int d[];
  int ma[1:2][0:2], mb[0:2][5:4], mc[2][2], bad[3][3], scratch[2][2];
  bit [127:0] w[4], x, xr;
  int unsigned v[4];
  initial begin
    foreach (a10[i]) a10[i] = i;
    foreach (a37[i]) a37[i] = -i;
    $display("LOG ex1 a10=%0d a37=%0d", ex1_sum(a10), ex1_sum(a37));

    ex2_query(m, q);
    $display("LOG ex2 left1=%0d right1=%0d low1=%0d high1=%0d inc1=%0d size1=%0d left2=%0d right2=%0d inc2=%0d size2=%0d dims=%0d bytes=%0d",
             q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], q[8], q[9], q[10], q[11]);

    foreach (data[i]) data[i] = byte'(i * 37);
    foreach (data[i]) ref_hist[8'(data[i]) >> 4]++;
    ex5_hist(data, hist);
    $display("LOG ex5 match=%0d bin0=%0d bin15=%0d", hist == ref_hist, hist[0], hist[15]);

    h = '{dst: 48'hAAAA_AAAA_AAAA, src: 48'h1234_5678_9ABC, etype: 16'h0806};
    ex7_swap_macs(h);
    $display("LOG ex7 dst=%h src=%h etype=%h", h.dst, h.src, h.etype);

    d = new[1000];
    foreach (d[i]) d[i] = i;
    $display("LOG ex9 sum=%0d expect=%0d", sum_dyn(d), d.sum() with (longint'(item)));

    foreach (ma[i, j]) ma[i][j] = i + j;
    foreach (mb[i, j]) mb[i][j] = i - j;
    begin
      int rc;                                          // no initializer: a static init would run at t=0, before ma/mb are filled
      rc = ex10_matmul(ma, mb, mc);                    // call first: $display argument order is unspecified
      $display("LOG ex10 rc=%0d c00=%0d c01=%0d c10=%0d c11=%0d bad_rc=%0d",
               rc, mc[0][0], mc[0][1], mc[1][0], mc[1][1], ex10_matmul(ma, bad, scratch));   // NOT mc: output is copied back even on error
    end

    foreach (w[i]) begin w[i] = {4{32'(i * 32'h1234_5679 + 1)}}; xr ^= w[i]; end
    w[3][127] = 1'b1; xr[127] = ~xr[127];
    ex11_xor(w, x);
    $display("LOG ex11 x=%h match=%0d", x, x == xr);

    v = '{32'h8000_0001, 32'hF, 32'h1, 32'hFFFF_FFFF};
    ex12_shift_all(v, 4);
    $display("LOG ex12 left=%h,%h,%h,%h", v[0], v[1], v[2], v[3]);
    ex12_shift_all(v, -8);
    $display("LOG ex12 right=%h,%h,%h,%h", v[0], v[1], v[2], v[3]);
    ex12_shift_all(v, 40);
    $display("LOG ex12 big=%h", v[0]);
    $finish;
  end
endmodule
