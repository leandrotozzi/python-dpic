`timescale 1ns/1ns
// The portable way to give the book's memory REAL timing (Sample 12.40's #10/#20) on every
// simulator, Verilator included: SV owns time and PULLS commands from C; C owns the file and the check.
module top;
  import "DPI-C" function int  cmd_open(string fname);
  import "DPI-C" function int  cmd_next(output byte cmd, output int idx, addr, data);
  import "DPI-C" function void cmd_result(int idx, addr, data, longint t);
  import "DPI-C" function int  cmd_close();                 // returns #errors

  class Memory;
    int mem[];
    function new(int size); mem = new[size]; endfunction
    task read(int addr, output int data); #20 data = mem[addr]; endtask
    task write(int addr, int data);       #10 mem[addr] = data; endtask
  endclass

  Memory memq[$];
  int ticks;
  always #1 ticks++;                                        // proves the rest of the TB keeps running

  initial begin
    byte cmd; int idx, addr, data;            // C must write every output, even unused ones
    Memory m;                                 // NOT `Memory m = new(..)`: a static initializer runs once, at t=0
    void'(cmd_open("mem_oop.dat"));
    while (cmd_next(cmd, idx, addr, data)) begin
      case (cmd)
        "M": begin m = new(addr); memq.push_back(m); end
        "W": memq[idx].write(addr, data);
        "R": begin memq[idx].read(addr, data); cmd_result(idx, addr, data, $time); end
      endcase
    end
    $display("LOG pull errs=%0d t=%0t ticks=%0d", cmd_close(), $time, ticks);
    $finish;
  end
endmodule
