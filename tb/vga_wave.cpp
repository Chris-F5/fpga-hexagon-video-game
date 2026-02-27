#include <iostream>
#include "vga_wave.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // Enable VCD tracing

    vga_wave* dut = new vga_wave;         // Instantiate the VGA module

    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);          // Trace 99 levels of hierarchy
    tfp->open("vga.vcd");         // Open the VCD file

    // Simulate for enough cycles to see a few horizontal lines
    // 1 clock cycle = 2 sim times. A horizontal line is 800 clocks.
    // Let's simulate 2000 clocks (4000 sim times)
    for (int sim_time = 0; sim_time < 800*800*2; sim_time++) {
        dut->clk = sim_time % 2;  // Toggle clock
        dut->eval();              // Evaluate model
        tfp->dump(sim_time);      // Write values to VCD file
    }

    tfp->close();
    delete dut;
    delete tfp;
    
    std::cout << "Simulation complete. Generated vga.vcd" << std::endl;
    return 0;
}
