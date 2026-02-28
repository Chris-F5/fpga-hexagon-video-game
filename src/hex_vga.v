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
  reg [31:0] plane_x;
  reg [31:0] plane_y;

  reg [32*32:0] bitmap;

  vga my_vga (
      .clk(counter[1]),
      .x(screen_x),
      .y(screen_y),
      .VGA_HS(VGA_HS),
      .VGA_VS(VGA_VS)
  );

  hex_plane my_hex_plane (
      .clk(counter[1]),
      .bitmap(bitmap),
      .start_x(plane_x),
      .start_y(plane_y),
      .end_red(VGA_R),
      .end_green(VGA_G),
      .end_blue(VGA_B)
  );

  always @(posedge CLK100MHZ) begin
    counter <= counter + 1;
  end

  always @(posedge counter[1]) begin
    // PIPELINE STAGE 0
    plane_x <= (({22'b0, screen_x} + 2) % 640) << 11;
    plane_y <= (({22'b0, screen_y} + 2) % 640) << 11;

    bitmap[10*32+10] <= 1;
  end
endmodule
