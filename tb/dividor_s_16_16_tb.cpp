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

    // We will simulate for 400 clock cycles (800 sim times)
    for (int sim_time = 0; sim_time < 800; sim_time++) {
        dut->clk = sim_time % 2;  // Toggle clock

        // Provide test inputs
        if (sim_time == 0) {
            dut->dividend = 1625600;
            dut->divisor = 2032;
        } else if (sim_time == 20) { // 10 clock cycles in
            dut->dividend = 500;
            dut->divisor = 7;
        } else if (sim_time == 40) { // 20 clock cycles in
            dut->dividend = -100;
            dut->divisor = 3;
        } else if (sim_time == 60) { // 30 clock cycles in
            dut->dividend = 500;
            dut->divisor = -7;
        } else if (sim_time == 80) { // 40 clock cycles in
            dut->dividend = -500;
            dut->divisor = -7;
        } else if (sim_time == 100) { // 50 clock cycles in
            dut->dividend = 81280;
            dut->divisor = 260096;
        } else if (sim_time == 120) { // 60 clock cycles in
            dut->dividend = 1073741823;
            dut->divisor = 1;
        } else if (sim_time == 140) { // 70 clock cycles in
            dut->dividend = -1073741824;
            dut->divisor = 1;
        } else if (sim_time == 160) { // 80 clock cycles in
            dut->dividend = -1073741824;
            dut->divisor = -1;
        } else if (sim_time == 180) { // 90 clock cycles in
            dut->dividend = 0;
            dut->divisor = 5;
        } else if (sim_time == 200) { // 100 clock cycles in
            dut->dividend = 123456;
            dut->divisor = 0;
        } else if (sim_time == 220) { // 110 clock cycles in
            dut->dividend = 1073741823;
            dut->divisor = 1073741823;
        } else if (sim_time == 240) { // 120 clock cycles in
            dut->dividend = -1073741824;
            dut->divisor = 1073741823;
        } else if (sim_time == 260) { // 130 clock cycles in
            dut->dividend = 9999999;
            dut->divisor = 333;
        } else if (sim_time == 280) { // 140 clock cycles in
            dut->dividend = -8888888;
            dut->divisor = 222;
        } else if (sim_time == 300) { // 150 clock cycles in
            dut->dividend = 7777777;
            dut->divisor = -111;
        }

        dut->eval();              // Evaluate model
        tfp->dump(sim_time);      // Write values to VCD file
        
        // Print output at specific cycles
        if (dut->clk == 0) { // Read when clock is low (stable output)
            int cycle = sim_time / 2;
            int32_t result = dut->quotient | (dut->quotient & 0x40000000 ? 0x80000000 : 0);
            
            // Output pipeline is now 32 cycles (31 stages + 1 cycle for sign application)
            if (cycle == 32) {
                std::cout << "Cycle " << cycle << ": 1625600 / 2032 = " << result << std::endl;
            }
            if (cycle == 42) {
                std::cout << "Cycle " << cycle << ": 500 / 7 = " << result << std::endl;
            }
            if (cycle == 52) {
                std::cout << "Cycle " << cycle << ": -100 / 3 = " << result << std::endl;
            }
            if (cycle == 62) {
                std::cout << "Cycle " << cycle << ": 500 / -7 = " << result << std::endl;
            }
            if (cycle == 72) {
                std::cout << "Cycle " << cycle << ": -500 / -7 = " << result << std::endl;
            }
            if (cycle == 82) {
                std::cout << "Cycle " << cycle << ": 81280 / 260096 = " << result << std::endl;
            }
            if (cycle == 92) {
                std::cout << "Cycle " << cycle << ": 1073741823 / 1 = " << result << std::endl;
            }
            if (cycle == 102) {
                std::cout << "Cycle " << cycle << ": -1073741824 / 1 = " << result << std::endl;
            }
            if (cycle == 112) {
                std::cout << "Cycle " << cycle << ": -1073741824 / -1 = " << result << std::endl;
            }
            if (cycle == 122) {
                std::cout << "Cycle " << cycle << ": 0 / 5 = " << result << std::endl;
            }
            if (cycle == 132) {
                std::cout << "Cycle " << cycle << ": 123456 / 0 = " << result << std::endl;
            }
            if (cycle == 142) {
                std::cout << "Cycle " << cycle << ": 1073741823 / 1073741823 = " << result << std::endl;
            }
            if (cycle == 152) {
                std::cout << "Cycle " << cycle << ": -1073741824 / 1073741823 = " << result << std::endl;
            }
            if (cycle == 162) {
                std::cout << "Cycle " << cycle << ": 9999999 / 333 = " << result << std::endl;
            }
            if (cycle == 172) {
                std::cout << "Cycle " << cycle << ": -8888888 / 222 = " << result << std::endl;
            }
            if (cycle == 182) {
                std::cout << "Cycle " << cycle << ": 7777777 / -111 = " << result << std::endl;
            }
        }
    }

    tfp->close();
    delete dut;
    delete tfp;
    
    std::cout << "Simulation complete. Generated dividor_s_16_16.vcd" << std::endl;
    return 0;
}
