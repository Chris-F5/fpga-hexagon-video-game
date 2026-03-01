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
  // The user inputs are passed to this module in the following way: when clock
  // is on the rising edge, if one of `key_*` are high, then it
  // means the user has just pressed that movement key. I.e. we dont know if
  // they are holding down the key, we only know if they have just pressed it
  // this clock cycle.
  // The input keys available to the module are arranged in a hexagonal patter
  // on the starndard qwerty keyboard. Each key corresponds to moving in one
  // of the 6 directions from one hexagon to an adjacent.

  // `bitmap` is indexed by the `q` and `r coordinates of hexagonal "cube"
  // coordinates described here: https://www.redblobgames.com/grids/hexagons/#pixel-to-hex
  // E.g. a hexagon is occupied iff `bitmap[q*32+r] == 1` for (q,r,s) where q+r+s=0.

  // `player_q` and `player_r` represent the player q and r coordinates where
  // (q,r,s) are its full coordinates and q+r+s=0.

  // Your job is to write the code for the game logic of the classic puzzle game
  // where the player moves on a grid, and when they leave a tile, that tile
  // becomes occupied (set in `bitmap`) and can no longer be visited again. The
  // players goal is to visit all locations on the grid. But the twist is that
  // we will be on a hexagonal grid instead of a square grid.


  // On the rst signal, set the player to an initial location and set the puzzles
  // initial configuration by using the `bitmap` (i.e. the starting walls).

  // On clk, if any of the keys are pressed move the player in that direction
  // if the new tile is not set in bitmap.
  // When the player leaves a tile, mark that tile in the bitmap.

endmodule
