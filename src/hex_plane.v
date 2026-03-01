module hex_plane (
    input clk,  // 2 pipeline stages
    input [32*32:0] bitmap,
    input [15:0] player_q,
    input [15:0] player_r,
    input signed [31:0] start_x,  // Q16.
    input signed [31:0] start_y,  // Q16.
    output reg [3:0] end_red,
    output reg [3:0] end_green,
    output reg [3:0] end_blue
);
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
  reg distance_0;
  reg distance_1;

  wire signed [47:0] start_x_48 = {{16{start_x[31]}}, start_x};
  wire signed [47:0] start_y_48 = {{16{start_y[31]}}, start_y} + 50000;
  wire signed [47:0] qd_48 = (start_x_48 * 43691) >>> 12;
  wire signed [47:0] rd_48 = (start_x_48 * (-21845) + start_y_48 * 37837) >>> 12;

  always @(posedge clk) begin
    // PIPELINE STAGE 0
    // 43691 = 2**16 * (2/3)
    // 21845 = 2**16 * (1/3)
    // 37837 = 2**16 * (sqrt(3)/3)
    //qd <= (start_x_48 * 43691) >>> 12;
    //rd <= (start_x_48 * (-21845) + start_y_48 * 37837) >>> 12;
    qd <= $signed(qd_48[31:0]);
    rd <= $signed(rd_48[31:0]);

    //if (start_x > 100) distance_0 <= 1;
    //else distance_0 <= 0;
    if (start_x[31] || (!start_x[31] && start_x > 180000)
      || start_y[31] || (!start_y[31] && start_y > 200000))
      distance_0 <= 1;
    else distance_0 <= 0;


    // PIPELINE STAGE 1
    distance_1 <= distance_0;


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

    // palette
    // EAF7CF CEB5A7 92828D ADAABF
    // (15,15,12) (13, 11, 10) (9, 8, 8) (11, 11, 12)

    // PIPELINE STAGE 2
    end_red   <= distance_1 | bitmap[q*32+r] ? (q[0] ? 9 : 11) : (q == player_q && r == player_r ? 15 : 0);
    end_blue  <= distance_1 | bitmap[q*32+r] ? (q[0] ? 8 : 11) : (q == player_q && r == player_r ? 15 : 0);
    end_green <= distance_1 | bitmap[q*32+r] ? (r[0] ? 8 : 12) : (q == player_q && r == player_r ? 15 : 0);
    //end_blue  <= r[0] ? 15 : 0;
    //end_blue  <= (!distance_1 && bitmap[q*32+r]) ? 15 : 0;
    //end_green <= distance_1 ? 15 : 0;
  end
endmodule
