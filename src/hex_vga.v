module hex_vga (
    input CLK100MHZ,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS
);
  reg [1:0] counter;

  wire [9:0] screen_x;
  wire [9:0] screen_y;
  reg signed [16:0] plane_x;  // these should probably be wires
  reg signed [16:0] plane_y;  // these should probably be wires
  wire projection_valid;
  reg signed [31:0] plane_x_dummy;
  reg signed [31:0] plane_y_dummy;
  wire [9:0] pipeline_front_screen_x;
  wire [9:0] pipeline_front_screen_y;

  reg [7:0] yaw = 0;
  reg [7:0] pitch = 40;

  // TODO: find the right look-ahead amount here.
  assign pipeline_front_screen_x = (screen_x + 20) % 640;
  assign pipeline_front_screen_y = screen_y % 480;

  reg [32*32:0] bitmap;

  vga my_vga (
      .clk(counter[1]),
      .x(screen_x),
      .y(screen_y),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS)
  );

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

  hex_plane my_hex_plane (
      .clk(counter[1]),
      .bitmap(bitmap),
      .start_x(projection_valid ? plane_x_dummy : 0),
      .start_y(projection_valid ? plane_y_dummy : 0),
      .end_red(VGA_R),
      .end_green(VGA_G),
      .end_blue(VGA_B)
  );

  always @(posedge CLK100MHZ) begin
    counter <= counter + 1;
  end

  always @(posedge counter[1]) begin
    // PIPELINE STAGE 0
    //plane_x_dummy <= (({22'b0, screen_x} + 2) % 640) << 11;
    //plane_y_dummy <= (({22'b0, screen_y} + 2) % 480) << 11;
    plane_x_dummy <= ({{15{plane_x[16]}}, plane_x} + 360) << 8;
    plane_y_dummy <= ({{15{plane_y[16]}}, plane_y} + 280) << 8;

    bitmap[10*32+10] <= 1;
  end
  always @(posedge VGA_VS) begin
    yaw <= yaw + 1;
    //pitch <= pitch + 1;
  end
endmodule
