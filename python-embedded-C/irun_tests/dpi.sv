// dpi.sv
module top;
  typedef int unsigned mem_t;
  mem_t mem[];

  import "DPI-C" context task ref_model ( inout mem_t m[] );
  export "DPI-C" task allocate_mem;

  task allocate_mem ( input int size );
    $display("SV: allocating new SV DA of size %0d", size);
    mem = new[size];
  endtask

  initial begin
    ref_model(mem);
    $display("SV: ref model finished, mem.size()=%0d", mem.size());
    foreach (mem[i]) $display("SV: mem[%0d]=%0d", i,mem[i]);
  end
endmodule