// Samples 12.22-12.25 (corrected): open arrays. The [] in the import means
// "any size, any range"; C receives an svOpenArrayHandle (a descriptor, not data).
import "DPI-C" function void fib_oa(output bit [31:0] data[]);
import "DPI-C" function void query(input int a[][], output int q[11]);
import "DPI-C" function void mydisplay(inout int a[][]);
import "DPI-C" function int  sum_oa(input int a[]);
import "DPI-C" function int  has_ptr(input int a[]);
import "DPI-C" function int  has_ptr_b(input bit [7:0] a[]);
import "DPI-C" function void flat(input int a[], input int m[][]);
import "DPI-C" function int  dimcheck(input int m[][]);
import "DPI-C" function int  probe_oob(input int a[]);

module top;
  bit [31:0] fibs[20];
  int a[6:1][8:3];                       // Sample 12.24: descending ranges, not 0-based
  int up[0:2][0:3];                      // ascending ranges for svIncrement
  int q[11];
  int fixed10[10:1];
  bit [7:0] bytes8[8];
  initial begin
    fib_oa(fibs);
    $display("LOG fib_oa d19=%0d", fibs[19]);
    query(a, q);
    $display("LOG query_a left1=%0d right1=%0d low1=%0d high1=%0d inc1=%0d size1=%0d left2=%0d right2=%0d size2=%0d dims=%0d bytes=%0d",
             q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], q[8], q[9], q[10]);
    query(up, q);
    $display("LOG query_up left1=%0d right1=%0d low1=%0d high1=%0d inc1=%0d size1=%0d left2=%0d right2=%0d size2=%0d dims=%0d bytes=%0d",
             q[0], q[1], q[2], q[3], q[4], q[5], q[6], q[7], q[8], q[9], q[10]);
    foreach (a[i, j]) a[i][j] = i + j;
    mydisplay(a);                        // C writes a[i][j] = i*j back
    $display("LOG mydisplay a63=%0d a13=%0d a48=%0d", a[6][3], a[1][3], a[4][8]);
    foreach (fixed10[i]) fixed10[i] = i;                      // 1..10 -> 55
    $display("LOG sum_oa fixed=%0d", sum_oa(fixed10));
    $display("LOG ptr int=%0d byte=%0d", has_ptr(fixed10), has_ptr_b(bytes8));
    flat(fixed10, a);
    $display("LOG dimcheck ret=%0d", dimcheck(a));
    $display("LOG oob ret=%0d", probe_oob(fixed10));
    $finish;
  end
endmodule
