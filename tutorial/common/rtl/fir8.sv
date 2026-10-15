// 8-tap FIR, signed Q1.15 samples and coefficients. Latency: 1 clock.
//   acc = sum_{k=0..7} coef[k] * x[n-k]        (35 bits, lossless)
//   y   = sat16( (acc + 2**14) >>> 15 )        (round half-up, saturate to int16)
// The delay line resets to 0 and only shifts when in_valid=1.
module fir8 (
  input  logic               clk,
  input  logic               rst_n,
  input  logic signed [15:0] coef [8],
  input  logic               in_valid,
  input  logic signed [15:0] in_x,
  output logic               out_valid,
  output logic signed [15:0] out_y
);
  logic signed [15:0] dly [8];        // dly[k] = x[n-1-k]; in_x = x[n]
  logic signed [34:0] acc;
  logic signed [34:0] rnd;

  always_comb begin
    acc = 35'(coef[0] * in_x);
    for (int k = 1; k < 8; k++) acc += 35'(coef[k] * dly[k-1]);
    rnd = (acc + 35'sd16384) >>> 15;
  end

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      for (int k = 0; k < 8; k++) dly[k] <= '0;
      out_valid <= 1'b0;
      out_y     <= '0;
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
        dly[0] <= in_x;
        for (int k = 1; k < 8; k++) dly[k] <= dly[k-1];
        out_y <= (rnd >  35'sd32767) ? 16'sd32767 :
                 (rnd < -35'sd32768) ? -16'sd32768 : 16'(rnd);
      end
    end
endmodule
