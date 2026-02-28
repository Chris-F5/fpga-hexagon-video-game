#include <iostream>
#include "dividor_s_16_16_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable VCD tracing

    dividor_s_16_16_tb* dut = new dividor_s_16_16_tb;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);          // Trace 99 levels of hierarchy
    tfp->open("dividor_s_16_16.vcd");     // Open the VCD file

    // We will simulate for 200 clock cycles (400 sim times)
    for (int sim_time = 0; sim_time < 400; sim_time++) {
        dut->clk = sim_time % 2;  // Toggle clock

        // Provide test inputs
        if (sim_time == 0) {
            dut->dividend = 16256*100;
            dut->divisor = 2032;
        } else if (sim_time == 20) { // 10 clock cycles in
            dut->dividend = 500;
            dut->divisor = 7;
        } else if (sim_time == 40) { // 20 clock cycles in
            dut->dividend = -100; // testing negative dividend
            dut->divisor = 3;
        } else if (sim_time == 60) { // 30 clock cycles in
            dut->dividend = 500;
            dut->divisor = -7; // testing negative divisor
        } else if (sim_time == 80) { // 40 clock cycles in
            dut->dividend = -500;
            dut->divisor = -7; // testing both negative
        }

        dut->eval();              // Evaluate model
        tfp->dump(sim_time);      // Write values to VCD file
        
        // Print output at specific cycles
        if (dut->clk == 0) { // Read when clock is low (stable output)
            int cycle = sim_time / 2;
            
            // Output pipeline is now 18 cycles (17 stages + 1 cycle for sign application)
            if (cycle == 18) {
                std::cout << "Cycle " << cycle << ": 1625600 / 2032 = " << (int32_t)(dut->quotient | (dut->quotient & 0x10000 ? 0xFFFE0000 : 0)) << std::endl;
            }
            if (cycle == 28) { // 10 cycles input delay + 18 cycles pipeline
                std::cout << "Cycle " << cycle << ": 500 / 7 = " << (int32_t)(dut->quotient | (dut->quotient & 0x10000 ? 0xFFFE0000 : 0)) << std::endl;
            }
            if (cycle == 38) { // 20 cycles input delay + 18 cycles pipeline
                std::cout << "Cycle " << cycle << ": -100 / 3 = " << (int32_t)(dut->quotient | (dut->quotient & 0x10000 ? 0xFFFE0000 : 0)) << std::endl;
            }
            if (cycle == 48) { // 30 cycles input delay + 18 cycles pipeline
                std::cout << "Cycle " << cycle << ": 500 / -7 = " << (int32_t)(dut->quotient | (dut->quotient & 0x10000 ? 0xFFFE0000 : 0)) << std::endl;
            }
            if (cycle == 58) { // 40 cycles input delay + 18 cycles pipeline
                std::cout << "Cycle " << cycle << ": -500 / -7 = " << (int32_t)(dut->quotient | (dut->quotient & 0x10000 ? 0xFFFE0000 : 0)) << std::endl;
            }
        }
    }

    tfp->close();
    delete dut;
    delete tfp;
    
    std::cout << "Simulation complete. Generated dividor_s_16_16.vcd" << std::endl;
    return 0;
}
