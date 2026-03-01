#include <SDL2/SDL.h>
#include <iostream>
#include <cmath>
#include "game_logic_tb.h"
#include "verilated.h"

void draw_hex(SDL_Renderer* renderer, float x, float y, float size, bool is_player, bool is_occupied) {
    SDL_Point points[7];
    for (int i = 0; i <= 6; ++i) {
        float angle_deg = 60 * i - 30;
        float angle_rad = M_PI / 180 * angle_deg;
        points[i].x = x + size * cos(angle_rad);
        points[i].y = y + size * sin(angle_rad);
    }
    
    if (is_player) {
        SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255); // Green for player
        // Draw some simple inner lines for player
        for (int i = 0; i < 6; ++i) {
            SDL_RenderDrawLine(renderer, x, y, points[i].x, points[i].y);
        }
        SDL_RenderDrawLines(renderer, points, 7);
    } else if (is_occupied) {
        SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255); // Red for occupied (wall/visited)
        // Draw a small cross
        SDL_RenderDrawLine(renderer, x - size/2, y - size/2, x + size/2, y + size/2);
        SDL_RenderDrawLine(renderer, x - size/2, y + size/2, x + size/2, y - size/2);
        SDL_RenderDrawLines(renderer, points, 7);
    } else {
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // White for empty path
        SDL_RenderDrawLines(renderer, points, 7);
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    game_logic_tb* dut = new game_logic_tb;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "Hex Game Simulator",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        800, 600, SDL_WINDOW_SHOWN
    );

    if (!window) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    
    bool quit = false;
    SDL_Event e;

    dut->rst = 1;
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->rst = 0;

    const float HEX_SIZE = 25.0f;
    const float OFFSET_X = 400.0f;
    const float OFFSET_Y = 300.0f;

    while (!quit) {
        // Reset keys for this cycle
        dut->key_y = 0;
        dut->key_u = 0;
        dut->key_k = 0;
        dut->key_m = 0;
        dut->key_n = 0;
        dut->key_h = 0;

        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = true;
            } else if (e.type == SDL_KEYDOWN) {
                switch (e.key.keysym.sym) {
                    case SDLK_y: dut->key_y = 1; break;
                    case SDLK_u: dut->key_u = 1; break;
                    case SDLK_k: dut->key_k = 1; break;
                    case SDLK_m: dut->key_m = 1; break;
                    case SDLK_n: dut->key_n = 1; break;
                    case SDLK_h: dut->key_h = 1; break;
                    case SDLK_ESCAPE: quit = true; break;
                }
            }
        }

        // Clock cycle if any key is pressed to simulate edge
        if (dut->key_y || dut->key_u || dut->key_k || dut->key_m || dut->key_n || dut->key_h) {
            dut->clk = 0;
            dut->eval();
            dut->clk = 1;
            dut->eval();
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Render the board
        for (int q = 0; q < 32; ++q) {
            for (int r = 0; r < 32; ++r) {
                int q_centered = q - 15;
                int r_centered = r - 15;
                int s_centered = -(q_centered + r_centered);

                // Only draw the playable area (radius 5 for instance, even if game is radius 3)
                if (std::abs(q_centered) > 5 || std::abs(r_centered) > 5 || std::abs(s_centered) > 5) {
                    continue;
                }

                int index = q * 32 + r;
                int word = index / 32;
                int bit = index % 32;
                bool is_occupied = (dut->bitmap[word] & (1U << bit)) != 0;
                bool is_player = (dut->player_q == q && dut->player_r == r);
                
                float x = OFFSET_X + HEX_SIZE * sqrt(3.0f) * (q_centered + r_centered / 2.0f);
                float y = OFFSET_Y + HEX_SIZE * 3.0f / 2.0f * r_centered;
                
                draw_hex(renderer, x, y, HEX_SIZE, is_player, is_occupied);
            }
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16); // roughly 60fps
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    
    delete dut;

    return 0;
}
