// CRC-32/IEEE 802.3 (Ethernet, zip, Python's zlib.crc32): reflected, poly 0xEDB88320,
// init 0xFFFFFFFF, xorout 0xFFFFFFFF. Consumes 1 byte per clock when in_valid=1.
// clear has priority: reloads init (start of a new message).
// crc is combinational from the register: the CRC of all bytes accepted so far.
module crc32_stream (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        clear,
  input  logic        in_valid,
  input  logic [7:0]  in_data,
  output logic [31:0] crc
);
  localparam logic [31:0] POLY = 32'hEDB8_8320;
  logic [31:0] state_q, state_d;

  always_comb begin
    state_d = state_q ^ {24'h0, in_data};
    for (int b = 0; b < 8; b++)
      state_d = state_d[0] ? (state_d >> 1) ^ POLY : (state_d >> 1);
  end

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)        state_q <= '1;
    else if (clear)    state_q <= '1;
    else if (in_valid) state_q <= state_d;

  assign crc = ~state_q;
endmodule
