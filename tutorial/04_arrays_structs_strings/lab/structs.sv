// Samples 12.28-12.29 + what else can cross: packed structs (always), unpacked structs (?).
typedef struct packed { bit [7:0] r, g, b; } RGB_T;            // 24 bits: r=[23:16] g=[15:8] b=[7:0]
typedef struct packed { bit [47:0] dst, src; bit [15:0] etype; } eth_hdr_t;   // 112 bits
import "DPI-C" function void invert(inout RGB_T p);              // book: struct-pointer cast
import "DPI-C" function void invert_bits(inout RGB_T p);         // portable: shifts on svBitVecVal
import "DPI-C" function int  etype_of(input eth_hdr_t h);
import "DPI-C" function void make_hdr(output eth_hdr_t h);
`ifdef UNPACKED
typedef struct { int a; byte b; shortint c; } ups_t;
import "DPI-C" function int  ups_sum(input ups_t s);
`endif

module top;
  RGB_T     px;
  eth_hdr_t h;
  initial begin
    px = '{r: 8'h12, g: 8'h34, b: 8'h56};
    invert(px);
    $display("LOG invert r=%h g=%h b=%h", px.r, px.g, px.b);
    invert_bits(px);
    $display("LOG invert_bits r=%h g=%h b=%h", px.r, px.g, px.b);
    h = '{dst: 48'hFFFF_FFFF_FFFF, src: 48'h0200_0000_0001, etype: 16'h0800};
    $display("LOG etype c=%h", etype_of(h));
    make_hdr(h);
    $display("LOG make_hdr dst=%h src=%h etype=%h", h.dst, h.src, h.etype);
`ifdef UNPACKED
    begin ups_t s = '{a: 1000, b: 8'sd20, c: 16'sd300}; $display("LOG ups sum=%0d", ups_sum(s)); end
`endif
    $finish;
  end
endmodule
