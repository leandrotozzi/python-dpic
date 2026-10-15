// H.10.1.3: svDpiVersion() names the DPI C layer the simulator implements.
// "1800-2005" = the canonical svBitVecVal/svLogicVecVal representation used in this step.
module top;
  import "DPI-C" function string dpi_version();
  initial begin $display("LOG ver dpi=%s", dpi_version()); $finish; end
endmodule
