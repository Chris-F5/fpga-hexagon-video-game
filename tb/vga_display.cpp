#include <SDL2/SDL.h>
#include <iostream>
#include "vga_display.h"
#include "verilated.h"

// VGA 640x480 @ 60Hz Industry Standard Timings
const int H_SYNC = 96;
const int H_BACK_PORCH = 48;
const int H_DISPLAY = 640;
const int H_FRONT_PORCH = 16;
const int H_TOTAL = H_SYNC + H_BACK_PORCH + H_DISPLAY + H_FRONT_PORCH; // 800

const int V_SYNC = 2;
const int V_BACK_PORCH = 29;
const int V_DISPLAY = 480;
const int V_FRONT_PORCH = 10;
const int V_TOTAL = V_SYNC + V_BACK_PORCH + V_DISPLAY + V_FRONT_PORCH; // 521

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    // Initialize SDL2
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::cerr << "SDL could not initialize! SDL_Error: " << SDL_GetError() << std::endl;
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "VGA Simulator (640x480)",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        H_DISPLAY, V_DISPLAY,
        SDL_WINDOW_SHOWN
    );

    if (!window) {
        std::cerr << "Window could not be created! SDL_Error: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_Texture* texture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        H_DISPLAY, V_DISPLAY
    );

    vga_display* dut = new vga_display;

    // Allocate framebuffer
    uint32_t* framebuffer = new uint32_t[H_DISPLAY * V_DISPLAY];

    bool quit = false;
    SDL_Event e;

    int h_count = 0;
    int v_count = 0;
    uint8_t prev_hs = 1;
    uint8_t prev_vs = 1;

    bool key_r_pressed = false;
    bool key_w_pressed = false;
    bool key_a_pressed = false;
    bool key_s_pressed = false;
    bool key_d_pressed = false;

    // Initialize inputs
    dut->CLK100MHZ = 0;
    dut->key_r = 0;
    dut->key_w = 0;
    dut->key_a = 0;
    dut->key_s = 0;
    dut->key_d = 0;
    dut->eval();

    // Simulation loop
    while (!quit) {
        // Handle SDL Events
        while (SDL_PollEvent(&e) != 0) {
            if (e.type == SDL_QUIT) {
                quit = true;
            } else if (e.type == SDL_KEYDOWN && !e.key.repeat) {
                switch (e.key.keysym.sym) {
                    case SDLK_r: key_r_pressed = true; break;
                    case SDLK_w: key_w_pressed = true; break;
                    case SDLK_a: key_a_pressed = true; break;
                    case SDLK_s: key_s_pressed = true; break;
                    case SDLK_d: key_d_pressed = true; break;
                    case SDLK_b: key_s_pressed = true; break;
                }
            }
        }

        bool frame_done = false;

        // Run simulation until one frame is completed
        while (!frame_done && !quit) {
            
            dut->key_r = key_r_pressed ? 1 : 0;
            dut->key_w = key_w_pressed ? 1 : 0;
            dut->key_a = key_a_pressed ? 1 : 0;
            dut->key_s = key_s_pressed ? 1 : 0;
            dut->key_d = key_d_pressed ? 1 : 0;
            
            // Clock high
            dut->CLK100MHZ = 1;
            dut->eval();
            
            key_r_pressed = false;
            key_w_pressed = false;
            key_a_pressed = false;
            key_s_pressed = false;
            key_d_pressed = false;
            
            dut->key_r = 0;
            dut->key_w = 0;
            dut->key_a = 0;
            dut->key_s = 0;
            dut->key_d = 0;

            // Detect falling edges of Syncs
            bool hs_falling = (prev_hs == 1 && dut->VGA_HS == 0);
            bool vs_falling = (prev_vs == 1 && dut->VGA_VS == 0);

            if (hs_falling) {
                h_count = 0;
            } else {
                h_count++;
            }

            if (vs_falling) {
                v_count = 0;
                frame_done = true; // A new frame has started
            } else if (hs_falling) {
                v_count++;
            }

            // Capture active pixel data
            if (h_count >= (H_SYNC + H_BACK_PORCH) && h_count < (H_SYNC + H_BACK_PORCH + H_DISPLAY)) {
                if (v_count >= (V_SYNC + V_BACK_PORCH) && v_count < (V_SYNC + V_BACK_PORCH + V_DISPLAY)) {
                    int px = h_count - (H_SYNC + H_BACK_PORCH);
                    int py = v_count - (V_SYNC + V_BACK_PORCH);

                    // 4-bit color to 8-bit color conversion (e.g. 0xF -> 0xFF)
                    uint8_t r = (dut->VGA_R << 4) | dut->VGA_R;
                    uint8_t g = (dut->VGA_G << 4) | dut->VGA_G;
                    uint8_t b = (dut->VGA_B << 4) | dut->VGA_B;

                    framebuffer[py * H_DISPLAY + px] = (0xFF << 24) | (r << 16) | (g << 8) | b;
                }
            }

            // Save state for next edge detection
            prev_hs = dut->VGA_HS;
            prev_vs = dut->VGA_VS;

            // Clock the 100Mhz clock to catch up with 25MHz
            dut->CLK100MHZ = 0;
            dut->eval();
            dut->CLK100MHZ = 1;
            dut->eval();
            dut->CLK100MHZ = 0;
            dut->eval();
            dut->CLK100MHZ = 1;
            dut->eval();
            dut->CLK100MHZ = 0;
            dut->eval();
            dut->CLK100MHZ = 1;
            dut->eval();
            dut->CLK100MHZ = 0;
            dut->eval();
        }

        // Render frame
        SDL_UpdateTexture(texture, NULL, framebuffer, H_DISPLAY * sizeof(uint32_t));
        SDL_RenderClear(renderer);
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    // Cleanup
    delete[] framebuffer;
    delete dut;
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}
