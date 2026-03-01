module projection (
    input clk,
    input [9:0] screen_x,
    input [9:0] screen_y,
    input [7:0] yaw,
    input [7:0] pitch,
    output wire signed [16:0] plane_x,
    output wire signed [16:0] plane_y,
    output reg valid
);
  reg signed [7:0] sin[255:0];

  // generate sin LUT.
  integer i;
  integer sin_val;
  real phase;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      phase   = (2.0 * 3.14159265 * i) / 256.0;
      sin_val = $rtoi($sin(phase) * 127.0);
      sin[i]  = sin_val[7:0];
    end
  end

  localparam inv_h = 16;  // h = 8  (128/h)
  localparam rot_d_0 = -1024 * 2;  // 1024 * 6;
  localparam rot_d_1 = 1024 * 2;
  wire signed [31:0] matrix_11;  // Q2.14
  wire signed [31:0] matrix_12;
  wire signed [31:0] matrix_13;
  wire signed [31:0] matrix_21;
  wire signed [31:0] matrix_22;
  wire signed [31:0] matrix_23;
  wire signed [31:0] matrix_31;  // Q2.14
  wire signed [31:0] matrix_32;
  wire signed [31:0] matrix_33;
  assign matrix_11 = sin[yaw+64] * 128;
  assign matrix_12 = -(sin[yaw] * sin[pitch+64]) - (((sin[yaw] * sin[pitch] * inv_h) >>> 14) * rot_d_1);
  assign matrix_13 = (sin[yaw] * sin[pitch]) - (((sin[yaw] * sin[pitch+64] * inv_h) >>> 14) * rot_d_1);
  assign matrix_21 = sin[yaw] * 128;
  assign matrix_22 = sin[yaw+64] * sin[pitch+64] + (((sin[yaw+64]*sin[pitch]*inv_h) >>> 14 ) * rot_d_1) - (((sin[pitch]*inv_h) >>> 7) *rot_d_0);
  assign matrix_23 = -(sin[yaw+64] * sin[pitch]) + (((sin[yaw+64]*sin[pitch+64]*inv_h) >>> 14 ) * rot_d_1) - (((sin[pitch+64]*inv_h) >>> 7 )*rot_d_0);
  assign matrix_31 = 0;
  assign matrix_32 = inv_h * sin[pitch];
  assign matrix_33 = inv_h * sin[pitch+64];

  reg signed  [10:0] screen_x_norm;  // Q1.9
  reg signed  [10:0] screen_y_norm;

  reg signed  [31:0] plane_xw;
  reg signed  [31:0] plane_yw;  // Q16.16
  reg signed  [31:0] plane_w;  // Q1.16

  wire signed [30:0] plane_x_out;
  wire signed [30:0] plane_y_out;
  assign plane_x = plane_x_out[16:0];
  assign plane_y = plane_y_out[16:0];

  dividor_s_16_16 x_divider (
      .clk(clk),
      .dividend(plane_xw[30:0]),
      .divisor(plane_w[30:0]),
      .quotient(plane_x_out)
  );
  dividor_s_16_16 y_divider (
      .clk(clk),
      .dividend(plane_yw[30:0]),
      .divisor(plane_w[30:0]),
      .quotient(plane_y_out)
  );

  reg valid_pipe[31:0];
  integer pipe_idx;

  always @(posedge clk) begin
    // STAGE 0
    screen_x_norm <= $signed({1'b0, screen_x}) - 320;  // Q1.9
    screen_y_norm <= $signed({1'b0, screen_y}) - 240;

    // STAGE 1
    // The matrix products result in 27 bits (16+11), we must explicitly resize matrix_13 to 32 bits to quiet warnings
    plane_xw <= (matrix_11 * screen_x_norm + matrix_12 * screen_y_norm + matrix_13 * 320) * 10;
    plane_yw <= (matrix_21 * screen_x_norm + matrix_22 * screen_y_norm + matrix_23 * 320) * 10;
    plane_w <= (matrix_31 * screen_x_norm + matrix_32 * screen_y_norm + matrix_33 * 320);

    // STAGES 2-33
    // divisor is operating. we must carry the validity condition.
    valid_pipe[0] <= (plane_w > 0);
    for (pipe_idx = 1; pipe_idx < 32; pipe_idx = pipe_idx + 1) begin
      valid_pipe[pipe_idx] <= valid_pipe[pipe_idx-1];
    end
    valid <= valid_pipe[31];
  end
endmodule
