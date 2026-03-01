module hello(
    input CLK100MHZ,
    inout PS2_CLK,
    inout PS2_DATA,
    output [0:0] LED,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output [6:0]SEG,
    output [7:0]AN,
    output DP
    );
    reg [25:0] count = 0;
    wire [31:0]keycode;
    assign LED[0] = count[25];
    
    wire key_flag;
    reg key_r;
    reg key_w;
    reg key_a;
    reg key_s;
    reg key_d;
    
    hex_vga my_vga(
      .CLK100MHZ (CLK100MHZ), // 100MHz clock
      .key_r(key_r),
      .key_w(key_w),
      .key_a(key_a),
      .key_s(key_s),
      .key_d(key_d),
      .VGA_R (VGA_R),
      .VGA_G (VGA_G),
      .VGA_B (VGA_B),
      .VGA_HS (VGA_HS),
      .VGA_VS (VGA_VS)
    );
    PS2Receiver keyboard (
      .clk(count[0]), // 50MHz clock 
      .kclk(PS2_CLK),
      .kdata(PS2_DATA),
      .keycodeout(keycode[31:0]),
      .flag(key_flag)
    );

    seg7decimal sevenSeg (
      .x(keycode[31:0]),
      .clk(CLK100MHZ),
      .seg(SEG[6:0]),
      .an(AN[7:0]),
      .dp(DP) 
    );
    reg [20:0] key_reset;
    always @ (posedge(CLK100MHZ)) begin
       count <= count + 1;
       if (count[0] && key_flag && key_reset == 0) begin
         key_reset <= 1000000; // 0.1sec reset
         if (keycode[7:0] == 8'h2d) key_r <= 1;
         if (keycode[7:0] == 8'h1d) key_w <= 1;
         if (keycode[7:0] == 8'h1c) key_a <= 1;
         if (keycode[7:0] == 8'h1b) key_s <= 1;
         if (keycode[7:0] == 8'h23) key_d <= 1;
       end else begin
         key_reset <= key_reset == 0 ? 0 : key_reset - 1;
         key_r <= 0;
         key_w <= 0;
         key_a <= 0;
         key_s <= 0;
         key_d <= 0;
       end
    end
endmodule