module hex_vga (
    input CLK100MHZ,
    input key_r,
    input key_y,
    input key_u,
    input key_k,
    input key_m,
    input key_n,
    input key_h,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);
  reg [1:0] counter;

  wire [32*32:0] bitmap;
  wire [15:0] player_q;
  wire [15:0] player_r;

  wire signed [9:0] screen_x;
  wire signed [9:0] screen_y;
  wire signed [16:0] plane_x;  // these should probably be wires
  wire signed [16:0] plane_y;  // these should probably be wires
  wire projection_valid;
  reg signed [31:0] plane_x_dummy;
  reg signed [31:0] plane_y_dummy;
  wire [9:0] pipeline_front_screen_x;
  wire [9:0] pipeline_front_screen_y;

  reg [7:0] yaw = 128;
  reg [7:0] pitch = 40;

  wire [3:0] plane_red;
  wire [3:0] plane_green;
  wire [3:0] plane_blue;

  // TODO: find the right look-ahead amount here. (I think 36)
  assign pipeline_front_screen_x = (screen_x + 36) % 640;
  assign pipeline_front_screen_y = screen_y % 480;

  game_logic my_game_logic (
      .clk(CLK100MHZ),
      .rst(key_r),
      .key_y(key_m),
      .key_u(key_n),  // lol
      .key_k(key_h),
      .key_m(key_y),
      .key_n(key_u),
      .key_h(key_k),
      .bitmap(bitmap),
      .player_q(player_q[4:0]),
      .player_r(player_r[4:0])
  );

  wire display_now;
  vga my_vga (
      .clk(counter[1]),
      .x(screen_x),
      .y(screen_y),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS),
      .display_now(display_now)
  );

  // 33 pipeline stages
  projection my_proj (
      .clk(counter[1]),  // TODO: clock at 100MHZ.
      .screen_x(pipeline_front_screen_x),
      .screen_y(pipeline_front_screen_y),
      .yaw(yaw),
      .pitch(pitch),
      .plane_x(plane_x),
      .plane_y(plane_y),
      .valid(projection_valid)
  );

  // 2 pipeline stages
  hex_plane my_hex_plane (
      .clk(counter[1]),
      .bitmap(bitmap),
      .player_q(player_q),
      .player_r(player_r),
      .start_x(projection_valid ? plane_x_dummy : 0),
      .start_y(projection_valid ? plane_y_dummy : 0),
      .end_red(plane_red),
      .end_green(plane_green),
      .end_blue(plane_blue)
  );
  wire display_active = (screen_y >= 0 && screen_y < 480) && display_now;
  assign VGA_R = (display_active ? plane_red : 0);
  assign VGA_G = (display_active ? plane_green : 0);
  assign VGA_B = (display_active ? plane_blue : 0);

  always @(posedge CLK100MHZ) begin
    counter <= counter + 1;
  end

  always @(posedge counter[1]) begin

    // 1 intermediate pipeline stage.

    //plane_x_dummy <= (({22'b0, screen_x} + 2) % 640) << 11;
    //plane_y_dummy <= (({22'b0, screen_y} + 2) % 480) << 11;
    plane_x_dummy <= ({{15{plane_x[16]}}, plane_x} + 360) << 8;
    plane_y_dummy <= ({{15{plane_y[16]}}, plane_y} + 280) << 8;

    //bitmap[10*32+10] <= 1;
  end
  always @(posedge VGA_VS) begin
    //yaw <= yaw + 6;
    //pitch <= pitch + 1;
  end
endmodule
