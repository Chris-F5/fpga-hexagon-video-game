#include <iostream>
#include <cmath>
#include <iomanip>
#include "projection_tb.h"
#include "projection_tb___024root.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// Helper function to calculate and print the matrix
// Since Verilator optimizes away pure combinational wires like matrix_11, 
// we compute them here using the internal sin table or math to show their values.
void print_matrix(projection_tb* dut, int cycle) {
    uint8_t yaw = dut->yaw;
    uint8_t pitch = dut->pitch;
    
    // Calculate indices with 8-bit wrapping
    uint8_t yaw_plus_64 = yaw + 64;
    uint8_t pitch_plus_64 = pitch + 64;

    // Fetch the raw sin values directly from the module's internal lookup table
    // (Note: CData is unsigned char, so we cast to int8_t for the signed value)
    int8_t sin_yaw         = (int8_t)dut->rootp->projection__DOT__sin[yaw];
    int8_t sin_pitch       = (int8_t)dut->rootp->projection__DOT__sin[pitch];
    int8_t sin_yaw_64      = (int8_t)dut->rootp->projection__DOT__sin[yaw_plus_64];
    int8_t sin_pitch_64    = (int8_t)dut->rootp->projection__DOT__sin[pitch_plus_64];

    // Reconstruct the matrix values as calculated in projection.v
    int32_t m11 = (sin_yaw_64 * 128);
    int32_t m12 = -(sin_yaw * sin_pitch_64);
    int32_t m13 = (sin_yaw * sin_pitch);
    int32_t m21 = (sin_yaw * 128);
    int32_t m22 = (sin_yaw_64 * sin_pitch_64);
    int32_t m23 = -(sin_yaw_64 * sin_pitch);
    int32_t m31 = 0;
    int32_t m32 = 16 * sin_pitch;
    int32_t m33 = 16 * sin_pitch_64;

    std::cout << "Cycle " << cycle << " Matrix (yaw=" << (int)yaw << ", pitch=" << (int)pitch << "):" << std::endl;
    std::cout << "  [" << std::setw(6) << m11 << ", " << std::setw(6) << m12 << ", " << std::setw(6) << m13 << "]" << std::endl;
    std::cout << "  [" << std::setw(6) << m21 << ", " << std::setw(6) << m22 << ", " << std::setw(6) << m23 << "]" << std::endl;
    std::cout << "  [" << std::setw(6) << m31 << ", " << std::setw(6) << m32 << ", " << std::setw(6) << m33 << "]" << std::endl;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable VCD tracing

    projection_tb* dut = new projection_tb;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);          // Trace 99 levels of hierarchy
    tfp->open("projection.vcd");  // Open the VCD file

    // Evaluate the model once so initial blocks execute!
    dut->eval();

    // Print the internal sine table at the start of simulation
    std::cout << "--- Sine Lookup Table ---" << std::endl;
    for (int i = 0; i < 256; i++) {
        int8_t val = (int8_t)dut->rootp->projection__DOT__sin[i];
        std::cout << "sin[" << std::setw(3) << i << "] = " << std::setw(4) << (int)val;
        if ((i + 1) % 8 == 0) std::cout << std::endl;
        else std::cout << "  |  ";
    }
    std::cout << "-------------------------" << std::endl;

    // We will simulate for 600 clock cycles (1200 sim times) to fit all 10 steps
    for (int sim_time = 0; sim_time < 1200; sim_time++) {
        dut->clk = sim_time % 2;  // Toggle clock

        if (sim_time % 2 == 0) {
            int cycle = sim_time / 2;
            
            // Fixed screen coordinate
            dut->screen_x = 325;
            dut->screen_y = 245;

            // Slowly increase yaw, then pitch
            if (cycle == 0)   { dut->yaw = 0; dut->pitch = 0; }
            if (cycle == 50)  { dut->yaw = 1; dut->pitch = 0; }
            if (cycle == 100) { dut->yaw = 2; dut->pitch = 0; }
            if (cycle == 150) { dut->yaw = 3; dut->pitch = 0; }
            if (cycle == 200) { dut->yaw = 4; dut->pitch = 0; }
            if (cycle == 250) { dut->yaw = 5; dut->pitch = 0; }
            
            if (cycle == 300) { dut->yaw = 0; dut->pitch = 1; }
            if (cycle == 350) { dut->yaw = 0; dut->pitch = 2; }
            if (cycle == 400) { dut->yaw = 0; dut->pitch = 3; }
            if (cycle == 450) { dut->yaw = 0; dut->pitch = 4; }
            if (cycle == 500) { dut->yaw = 0; dut->pitch = 5; }
        }

        dut->eval();              // Evaluate model
        tfp->dump(sim_time);      // Write values to VCD file
        
        // Print output at specific cycles
        if (dut->clk == 0) { // Read when clock is low (stable output)
            int cycle = sim_time / 2;
            
            // Print matrix when inputs change
            if (cycle % 50 == 1 && cycle <= 501) {
                print_matrix(dut, cycle);
            }

            // Print the resulting projection after the pipeline delay
            if (cycle % 50 == 34 && cycle <= 534) { 
                int32_t signed_plane_x = ((int32_t)(dut->plane_x << 15)) >> 15;
                int32_t signed_plane_y = ((int32_t)(dut->plane_y << 15)) >> 15;
                std::cout << "Cycle " << cycle << " -> plane_x=" << signed_plane_x << ", plane_y=" << signed_plane_y << std::endl;
            }
        }
    }

    tfp->close();
    delete dut;
    delete tfp;
    
    std::cout << "Simulation complete. Generated projection.vcd" << std::endl;
    return 0;
}
