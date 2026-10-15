// T9 test: 2 independent C++ FIFOs vs 2 SV queues under 2000 random push/pop operations.
import "DPI-C" function chandle fifo_new(input int depth);
import "DPI-C" function void    fifo_delete(input chandle f);
import "DPI-C" function int     fifo_push(input chandle f, input int unsigned v);
import "DPI-C" function int     fifo_pop(input chandle f, output int unsigned v);
import "DPI-C" function int     fifo_size(input chandle f);

module top;
  localparam int DEPTH = 8;
  chandle      m [2];
  int unsigned q [2][$];
  int errors, pushes, pops, rejects;
  initial begin
    foreach (m[k]) m[k] = fifo_new(DEPTH);
    for (int n = 0; n < 2000; n++) begin
      int k = $urandom_range(1);
      int unsigned v = $urandom, got;
      int ok;
      if ($urandom_range(1)) begin                       // push
        ok = fifo_push(m[k], v);
        if (ok != (q[k].size() < DEPTH)) errors++;
        if (ok) begin q[k].push_back(v); pushes++; end else rejects++;
      end else begin                                     // pop
        ok = fifo_pop(m[k], got);
        if (ok != (q[k].size() > 0)) errors++;
        if (ok) begin if (got != q[k].pop_front()) errors++; pops++; end else rejects++;
      end
      if (fifo_size(m[k]) != q[k].size()) errors++;
    end
    $display("LOG fifo errors=%0d pushes=%0d pops=%0d rejects=%0d", errors, pushes, pops, rejects);
    foreach (m[k]) fifo_delete(m[k]);
    $finish;
  end
endmodule
