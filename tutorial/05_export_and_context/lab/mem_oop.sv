`timescale 1ns/1ns
// Samples 12.43–12.45: many Memory objects behind exported wrapper functions.
// A class handle can't cross DPI, so C holds an INDEX into memq. Fix vs the book: mem_build
// RETURNS the index (the book's text says so, its code is `void` and C guesses the index).
module top;
  import "DPI-C" context function int read_file(string fname);
  export "DPI-C" function mem_build;
  export "DPI-C" function mem_read;
  export "DPI-C" function mem_write;

  class Memory;
    int mem[];
    function new(int size); mem = new[size]; endfunction
    function int  read(int addr);            return mem[addr]; endfunction
    function void write(int addr, int data); mem[addr] = data; endfunction
  endclass

  Memory memq[$];
  function automatic int mem_build(input int size);
    Memory m = new(size);
    memq.push_back(m);
    return memq.size() - 1;                      // the "handle" C gets
  endfunction
  function int  mem_read(input int idx, addr);          return memq[idx].read(addr); endfunction
  function void mem_write(input int idx, addr, data);   memq[idx].write(addr, data); endfunction

  initial begin
    int errs = read_file("mem_oop.dat");
    $display("LOG memoop n=%0d m0_12=%0d m1_12=%0d m0_99=%0d errs=%0d", memq.size(),
             memq[0].mem[12], memq[1].mem[12], memq[0].mem[99], errs);
    $finish;
  end
endmodule
