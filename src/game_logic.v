module game_logic (
    input clk,
    input rst,
    input key_w,
    input key_a,
    input key_s,
    input key_d,
    output reg [32*32:0] bitmap,
    output reg [4:0] player_q,
    output reg [4:0] player_r,
    output reg [2:0] player_dir
);

  reg [32*32:0] init_bitmap;
  integer i, j;
  reg signed [6:0] q_shift, r_shift, s_shift;
  initial begin
    init_bitmap = ~0;  // all 1s
    for (i = 0; i < 32; i = i + 1) begin
      for (j = 0; j < 32; j = j + 1) begin
        q_shift = i[6:0] - 7'd15;
        r_shift = j[6:0] - 7'd15;
        s_shift = -(q_shift + r_shift);
        if ((q_shift <= 3 && q_shift >= -3) &&
                  (r_shift <= 3 && r_shift >= -3) &&
                  (s_shift <= 3 && s_shift >= -3)) begin
          init_bitmap[i*32+j] = 0;
        end
      end
    end
    // add a few walls to make it interesting
    init_bitmap[14*32+15] = 1;
    init_bitmap[16*32+15] = 1;
  end

  wire [4:0] next_q_0_f = player_q;
  wire [4:0] next_r_0_f = player_r - 1;
  wire [4:0] next_q_0_b = player_q;
  wire [4:0] next_r_0_b = player_r + 1;

  wire [4:0] next_q_1_f = player_q + 1;
  wire [4:0] next_r_1_f = player_r - 1;
  wire [4:0] next_q_1_b = player_q - 1;
  wire [4:0] next_r_1_b = player_r + 1;

  wire [4:0] next_q_2_f = player_q + 1;
  wire [4:0] next_r_2_f = player_r;
  wire [4:0] next_q_2_b = player_q - 1;
  wire [4:0] next_r_2_b = player_r;

  wire [4:0] next_q_3_f = player_q;
  wire [4:0] next_r_3_f = player_r + 1;
  wire [4:0] next_q_3_b = player_q;
  wire [4:0] next_r_3_b = player_r - 1;

  wire [4:0] next_q_4_f = player_q - 1;
  wire [4:0] next_r_4_f = player_r + 1;
  wire [4:0] next_q_4_b = player_q + 1;
  wire [4:0] next_r_4_b = player_r - 1;

  wire [4:0] next_q_5_f = player_q - 1;
  wire [4:0] next_r_5_f = player_r;
  wire [4:0] next_q_5_b = player_q + 1;
  wire [4:0] next_r_5_b = player_r;

  reg [4:0] try_q, try_r;
  reg move;

  always @(posedge clk) begin
    try_q = player_q;
    try_r = player_r;
    move  = 0;

    if (key_w || key_s) begin
      move = 1;
      case (player_dir)
        0: begin
          try_q = key_w ? next_q_0_f : next_q_0_b;
          try_r = key_w ? next_r_0_f : next_r_0_b;
        end
        1: begin
          try_q = key_w ? next_q_1_f : next_q_1_b;
          try_r = key_w ? next_r_1_f : next_r_1_b;
        end
        2: begin
          try_q = key_w ? next_q_2_f : next_q_2_b;
          try_r = key_w ? next_r_2_f : next_r_2_b;
        end
        3: begin
          try_q = key_w ? next_q_3_f : next_q_3_b;
          try_r = key_w ? next_r_3_f : next_r_3_b;
        end
        4: begin
          try_q = key_w ? next_q_4_f : next_q_4_b;
          try_r = key_w ? next_r_4_f : next_r_4_b;
        end
        5: begin
          try_q = key_w ? next_q_5_f : next_q_5_b;
          try_r = key_w ? next_r_5_f : next_r_5_b;
        end
        default: begin
          try_q = player_q;
          try_r = player_r;
          move  = 0;
        end
      endcase
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      player_q <= 15;
      player_r <= 15;
      player_dir <= 0;
      bitmap <= init_bitmap;
    end else begin
      if (key_a) begin
        player_dir <= (player_dir == 0) ? 5 : player_dir - 1;
      end else if (key_d) begin
        player_dir <= (player_dir == 5) ? 0 : player_dir + 1;
      end

      if (move && bitmap[try_q*32+try_r] == 0) begin
        player_q <= try_q;
        player_r <= try_r;
        bitmap[player_q*32+player_r] <= 1;  // Mark old pos
      end
    end
  end

endmodule
