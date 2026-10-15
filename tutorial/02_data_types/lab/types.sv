// Experiment "types": the scalar part of the SV <-> C type mapping (IEEE 1800-2023 Annex H.7.4).
// Each import sends a value to C and gets it back; C also reports what it saw.
import "DPI-C" function void   c_sizes();
import "DPI-C" function byte              rt_byte    (input byte              v);
import "DPI-C" function byte unsigned     rt_ubyte   (input byte unsigned     v);
import "DPI-C" function shortint          rt_short   (input shortint          v);
import "DPI-C" function shortint unsigned rt_ushort  (input shortint unsigned v);
import "DPI-C" function int               rt_int     (input int               v);
import "DPI-C" function int unsigned      rt_uint    (input int unsigned      v);
import "DPI-C" function longint           rt_long    (input longint           v);
import "DPI-C" function longint unsigned  rt_ulong   (input longint unsigned  v);
import "DPI-C" function real              rt_real    (input real              v);
import "DPI-C" function shortreal         rt_sreal   (input shortreal         v);
import "DPI-C" function bit               rt_bit     (input bit               v);
import "DPI-C" function logic             rt_logic   (input logic             v);
import "DPI-C" function int               c_strlen   (input string            s);
import "DPI-C" function chandle           c_new_box  (input int               v);
import "DPI-C" function int               c_box_get  (input chandle           h);
import "DPI-C" function int               c_is_null  (input chandle           h);
import "DPI-C" function bit [6:0]         rt_bit7    (input bit [6:0]         v);  // packed result <= 32 bits: legal

typedef enum byte {IDLE = 1, BUSY = -2} state_e;
import "DPI-C" function state_e rt_enum(input state_e v);                        // enum = its base type

module top;
  chandle h;
  logic lx = 1'bx, lz = 1'bz;      // 4-state values held in variables (a 1'bz literal argument is a build error)
  initial begin
    c_sizes();
    $display("LOG byte min=%0d max=%0d", rt_byte(-128), rt_byte(127));
    $display("LOG ubyte max=%0d", rt_ubyte(255));
    $display("LOG short min=%0d max=%0d", rt_short(-32768), rt_short(32767));
    $display("LOG ushort max=%0d", rt_ushort(65535));
    $display("LOG int min=%0d max=%0d", rt_int(32'sh8000_0000), rt_int(32'sh7fff_ffff));
    $display("LOG uint max=%0d", rt_uint(32'hffff_ffff));
    $display("LOG long min=%0d max=%0d", rt_long(64'sh8000_0000_0000_0000), rt_long(64'sh7fff_ffff_ffff_ffff));
    $display("LOG ulong max=%0d", rt_ulong(64'hffff_ffff_ffff_ffff));
    $display("LOG real v=%0.17g", rt_real(0.1));
    $display("LOG sreal v=%0.17g", rt_sreal(0.1));
    $display("LOG bit v0=%b v1=%b", rt_bit(1'b0), rt_bit(1'b1));
    $display("LOG logic v0=%b v1=%b vx=%b vz=%b", rt_logic(1'b0), rt_logic(1'b1), rt_logic(lx), rt_logic(lz));
    $display("LOG string len=%0d empty=%0d", c_strlen("hello, DPI"), c_strlen(""));
    h = c_new_box(42);
    $display("LOG chandle get=%0d null_is_null=%0d h_is_null=%0d h_eq_null=%0d",
             c_box_get(h), c_is_null(null), c_is_null(h), h == null);
    $display("LOG bit7 v=%0d", rt_bit7(7'd100));
    $display("LOG enum v=%s", rt_enum(BUSY).name());
    $finish;
  end
endmodule
