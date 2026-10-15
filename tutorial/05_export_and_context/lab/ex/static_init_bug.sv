`timescale 1ns/1ns
// Exercise "find the bug": every read returns 0. (This bug was really hit while writing the lab.)
module top;
  import "DPI-C" function int  cmd_open(string fname);
  import "DPI-C" function int  cmd_next(output byte cmd, output int idx, addr, data);
  import "DPI-C" function void cmd_result(int idx, addr, data, longint t);
  import "DPI-C" function int  cmd_close();
  class Memory;
    int mem[];
    function new(int size); mem = new[size]; endfunction
    task read(int addr, output int data); #20 data = mem[addr]; endtask
    task write(int addr, int data);       #10 mem[addr] = data; endtask
  endclass
  Memory memq[$];
  initial begin
    byte cmd; int idx, addr, data;
    void'(cmd_open("mem_oop.dat"));
    while (cmd_next(cmd, idx, addr, data)) begin
      case (cmd)
        "M": begin Memory m = new(addr); memq.push_back(m); end
        "W": memq[idx].write(addr, data);
        "R": begin memq[idx].read(addr, data); cmd_result(idx, addr, data, $time); end
      endcase
    end
    $display("LOG bug errs=%0d same=%0d size0=%0d", cmd_close(), memq[0] == memq[1], memq[0].mem.size());
    $finish;
  end
endmodule
