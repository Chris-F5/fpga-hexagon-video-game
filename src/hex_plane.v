module hex_plane (
    input clk,  // 2 pipeline stages
    input [32*32:0] bitmap,
    input signed [31:0] start_x,  // Q16.16
    input signed [31:0] start_y,  // Q16.16
    output [3:0] end_red,
    output [3:0] end_green,
    output [3:0] end_blue
);
  /*
  reg signed  [31:0] qd;  // Q16.16
  reg signed  [31:0] rd;  // Q16.16
  wire signed [31:0] sd;  // Q16.16
  assign sd = -qd - rd;
  wire signed [31:0] qd_offset;
  wire signed [31:0] rd_offset;
  wire signed [31:0] sd_offset;
  assign qd_offset = qd + (1 << 14);
  assign rd_offset = rd + (1 << 14);
  assign sd_offset = sd + (1 << 14);
  wire [15:0] qd_round;  // Q16.0
  wire [15:0] rd_round;
  wire [15:0] sd_round;
  assign qd_round = qd_offset[31:16];
  assign rd_round = rd_offset[31:16];
  assign sd_round = sd_offset[31:16];
  wire [14:0] qd_err;  // Q0.16 (max is 1/2)
  wire [14:0] rd_err;
  wire [14:0] sd_err;
  assign qd_err = qd[15] ? qd_offset[14:0] : qd[14:0];
  assign rd_err = rd[15] ? rd_offset[14:0] : rd[14:0];
  assign sd_err = sd[15] ? sd_offset[14:0] : sd[14:0];
  reg signed [15:0] q;  // Q16.0
  reg signed [15:0] r;
  reg signed [15:0] s;
  */
  reg signed  [31:0] qd;  // Q16.16
  reg signed  [31:0] rd;
  wire signed [31:0] sd;
  assign sd = -qd - rd;
  wire [31:0] qd_offset;  // Q16.16
  wire [31:0] rd_offset;
  wire [31:0] sd_offset;
  assign qd_offset = qd + (1 << 15);
  assign rd_offset = rd + (1 << 15);
  assign sd_offset = sd + (1 << 15);
  wire [15:0] qd_round;
  wire [15:0] rd_round;
  wire [15:0] sd_round;
  assign qd_round = qd_offset[31:16];
  assign rd_round = rd_offset[31:16];
  assign sd_round = sd_offset[31:16];
  wire [14:0] qd_err;
  wire [14:0] rd_err;
  wire [14:0] sd_err;
  assign qd_err = qd_offset[15] ? qd_offset[14:0] : (1 << 15) - 1 - qd_offset[14:0];
  assign rd_err = rd_offset[15] ? rd_offset[14:0] : (1 << 15) - 1 - rd_offset[14:0];
  assign sd_err = sd_offset[15] ? sd_offset[14:0] : (1 << 15) - 1 - sd_offset[14:0];
  reg signed [15:0] q;
  reg signed [15:0] r;
  reg signed [15:0] s;

  reg [3:0] red;
  reg [3:0] green;
  reg [3:0] blue;
  assign end_red   = red;
  assign end_green = green;
  assign end_blue  = blue;



  always @(posedge clk) begin
    // PIPELINE STAGE 0
    // 43691 = 2**16 * (2/3)
    // 21845 = 2**16 * (1/3)
    // 37837 = 2**16 * (sqrt(3)/3)
    qd <= (start_x * 43691) >>> 15;  // weird that 15 works, id expect 16.
    rd <= (start_x * (-21845) + start_y * 37837) >>> 15;
    /*
    qd <= ((start_x[9:0]) * 11) >>> 4;
    rd <= ((start_x[9:0]) * (-5) + (start_y[9:0]) * (+9)) >>> 4;
    */


    // PIPELINE STAGE 1
    if (qd_err > rd_err && qd_err > sd_err) begin
      q <= -rd_round - sd_round;
      r <= rd_round;
      s <= sd_round;
    end else if (rd_err > sd_err) begin
      q <= qd_round;
      r <= -qd_round - sd_round;
      s <= sd_round;
    end else begin
      q <= qd_round;
      r <= rd_round;
      s <= -qd_round - rd_round;
    end

    // PIPELINE STAGE 2
    red   <= q[0] ? 15 : 0;
    blue  <= r[0] ? 15 : 0;
    green <= s[0] ? 15 : 0;
    //end_green <= bitmap[q*32+r] ? 15 : 0;
  end
endmodule
