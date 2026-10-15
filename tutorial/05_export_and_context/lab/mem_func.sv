`timescale 1ns/1ns
// Samples 12.37/12.38 grown to read+write: C parses the command file and drives SV through
// exported FUNCTIONS (zero time). Runs on any simulator, Verilator included.
module top;
  import "DPI-C" context function int read_file(string fname);   // returns #errors
  export "DPI-C" function mem_build;
  export "DPI-C" function mem_read;
  export "DPI-C" function mem_write;
  int mem[];
  function void mem_build(input int size);   mem = new[size];  endfunction
  function int  mem_read(input int addr);    return mem[addr]; endfunction
  function void mem_write(input int addr, input int data); mem[addr] = data; endfunction
  initial begin
    int errs = read_file("mem.dat");
    $display("LOG memf size=%0d m12=%0d m99=%0d errs=%0d t=%0t", mem.size(), mem[12], mem[99], errs, $time);
    $finish;
  end
endmodule
