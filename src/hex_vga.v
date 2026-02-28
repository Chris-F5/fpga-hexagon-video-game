module hex_vga (
    input CLK100MHZ,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);
  reg [1:0] counter;
  reg [3:0] this_red;
  reg [3:0] this_green;
  reg [3:0] this_blue;

  wire [9:0] this_x;
  wire [9:0] this_y;

  // construct pixel colors in a pipeline.
  reg signed [9:0] qd;  // Q5.4
  reg signed [9:0] rd;
  wire signed [9:0] sd;
  assign sd = -qd - rd;
  wire [(6+3):0] qd_offset;
  wire [(6+3):0] rd_offset;
  wire [(6+3):0] sd_offset;
  assign qd_offset = qd + 8;
  assign rd_offset = rd + 8;
  assign sd_offset = sd + 8;
  wire [5:0] qd_round;
  wire [5:0] rd_round;
  wire [5:0] sd_round;
  assign qd_round = qd_offset[(6+3):4];
  assign rd_round = rd_offset[(6+3):4];
  assign sd_round = sd_offset[(6+3):4];
  wire [2:0] qd_err;
  wire [2:0] rd_err;
  wire [2:0] sd_err;
  assign qd_err = qd_offset[3] ? qd_offset[2:0] : 7 - qd_offset[2:0];
  assign rd_err = rd_offset[3] ? rd_offset[2:0] : 7 - rd_offset[2:0];
  assign sd_err = sd_offset[3] ? sd_offset[2:0] : 7 - sd_offset[2:0];

  reg signed [5:0] q;
  reg signed [5:0] r;
  reg signed [5:0] s;

  reg [32*32:0] bitmap;

  vga my_vga (
      .clk(counter[1]),
      .x(this_x),
      .y(this_y),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS)
  );

  assign VGA_R = this_red;
  assign VGA_G = this_green;
  assign VGA_B = this_blue;

  localparam pipe_len = 2;
  localparam hex_size = 4;
  always @(posedge CLK100MHZ) begin
    counter <= counter + 1;
    // PIPELINE STAGE 0

    // 11 = 16*(2/3)
    //  5 = 16*(1/3)
    //  9 = 16*(sqrt(3)/3)
    qd      <= ((this_x + pipe_len) * 11) >>> 4;
    rd      <= ((this_x + pipe_len) * (-5) + (this_y) * (+9)) >>> 4;

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
    //this_red <= q[0] ? 15 : 0;
    //this_green <= r[0] ? 15 : 0;
    this_red <= q[0] ? 15 : 0;
    this_blue <= r[0] ? 15 : 0;
    this_green <= bitmap[q*32+r] ? 15 : 0;
    bitmap[10*32+10] <= 1;
  end
endmodule
