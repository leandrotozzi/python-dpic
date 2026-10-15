`timescale 1ns/1ns
// Exercise: Sample 12.40 (single memory, mem.dat) rewritten as a pull model that Verilator runs.
module top;
  import "DPI-C" function int  cmd_open(string fname);
  import "DPI-C" function int  cmd_next(output byte cmd, output int addr, data, exp);
  import "DPI-C" function int  cmd_close();
  int mem[];
  task mem_read(input int addr, output int data); #20 data = mem[addr]; endtask
  task mem_write(input int addr, input int data); #10 mem[addr] = data; endtask
  initial begin
    byte cmd; int addr, data, exp, got, errs;
    void'(cmd_open("mem.dat"));
    while (cmd_next(cmd, addr, data, exp))
      case (cmd)
        "M": mem = new[addr];
        "W": mem_write(addr, data);
        "R": begin
          mem_read(addr, got);
          if (got !== exp) begin errs++; $error("addr %0d: got %0d exp %0d", addr, got, exp); end
        end
      endcase
    void'(cmd_close());
    $display("LOG pull1 errs=%0d t=%0t", errs, $time);
    $finish;
  end
endmodule
