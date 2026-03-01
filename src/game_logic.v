module game_logic (
    input clk,
    input rst,
    input key_y,
    input key_u,
    input key_k,
    input key_m,
    input key_n,
    input key_h,
    output reg [32*32:0] bitmap,
    output reg [4:0] player_q,
    output reg [4:0] player_r
);

  reg [32*32:0] init_bitmap;
  integer i, j;
  reg signed [6:0] q_shift, r_shift, s_shift;
  initial begin
      init_bitmap = ~0; // all 1s
      for (i = 0; i < 32; i = i + 1) begin
          for (j = 0; j < 32; j = j + 1) begin
              q_shift = i[6:0] - 7'd15;
              r_shift = j[6:0] - 7'd15;
              s_shift = - (q_shift + r_shift);
              if ((q_shift <= 3 && q_shift >= -3) &&
                  (r_shift <= 3 && r_shift >= -3) &&
                  (s_shift <= 3 && s_shift >= -3)) begin
                  init_bitmap[i * 32 + j] = 0;
              end
          end
      end
      // add a few walls to make it interesting
      init_bitmap[14 * 32 + 15] = 1;
      init_bitmap[16 * 32 + 15] = 1;
  end

  wire [4:0] next_q_y = player_q;
  wire [4:0] next_r_y = player_r - 1;

  wire [4:0] next_q_u = player_q + 1;
  wire [4:0] next_r_u = player_r - 1;

  wire [4:0] next_q_k = player_q + 1;
  wire [4:0] next_r_k = player_r;

  wire [4:0] next_q_m = player_q;
  wire [4:0] next_r_m = player_r + 1;

  wire [4:0] next_q_n = player_q - 1;
  wire [4:0] next_r_n = player_r + 1;

  wire [4:0] next_q_h = player_q - 1;
  wire [4:0] next_r_h = player_r;

  reg [4:0] try_q, try_r;
  reg move;

  always @(posedge clk) begin
      if (rst) begin
          player_q <= 15;
          player_r <= 15;
          bitmap <= init_bitmap;
      end else begin
          try_q = player_q;
          try_r = player_r;
          move = 0;
          if (key_y) begin try_q = next_q_y; try_r = next_r_y; move = 1; end
          else if (key_u) begin try_q = next_q_u; try_r = next_r_u; move = 1; end
          else if (key_k) begin try_q = next_q_k; try_r = next_r_k; move = 1; end
          else if (key_m) begin try_q = next_q_m; try_r = next_r_m; move = 1; end
          else if (key_n) begin try_q = next_q_n; try_r = next_r_n; move = 1; end
          else if (key_h) begin try_q = next_q_h; try_r = next_r_h; move = 1; end

          if (move && bitmap[try_q * 32 + try_r] == 0) begin
              player_q <= try_q;
              player_r <= try_r;
              bitmap[player_q * 32 + player_r] <= 1;
          end
      end
  end

endmodule
