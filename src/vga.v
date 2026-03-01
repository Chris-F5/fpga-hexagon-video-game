module vga (
    input clk,  // this clock should be sent at 25MHz
    // output [3:0] VGA_R,
    // output [3:0] VGA_G,
    // output [3:0] VGA_B,
    output signed [9:0] x,
    output signed [9:0] y,
    output VGA_HS,
    output VGA_VS,
    output reg display_now
);
  // 640x480
  // These parameters correspond to the diagram on
  // https://digilent.com/reference/programmable-logic/nexys-a7/reference-manual
  localparam hTs = hTdisp + hTpw + hTfp + hTbp;  // period is 800 ticks.
  localparam hTdisp = 640;  // displaying for 640 ticks.
  localparam hTpw = 96;  // how long to hold low for.
  localparam hTfp = 16;  // how long to give after line.
  localparam hTbp = 48;  // how long to give before line.

  localparam vTs = vTdisp + vTpw + vTfp + vTbp;
  localparam vTdisp = 480;
  localparam vTpw = 2;
  localparam vTfp = 10;
  localparam vTbp = 29;

  reg [9:0] h;
  reg [9:0] v;

  assign VGA_HS = (h >= hTpw);
  assign VGA_VS = (v >= vTpw);

  // assign VGA_R  = h[3:0];
  // assign VGA_G  = v[3:0];
  // assign VGA_B  = 4'hf;

  assign x = h - hTpw - hTbp;
  assign y = v - vTpw - vTbp;

  always @(posedge clk) begin
    h <= (h + 1) % hTs;
    v <= (h == hTs - 1) ? (v + 1) % vTs : v;
    display_now <= (h > hTpw + hTbp && h < hTpw + hTbp + hTdisp)
                && (v > vTpw + vTbp && v < vTpw + vTbp + vTdisp);
  end
endmodule
