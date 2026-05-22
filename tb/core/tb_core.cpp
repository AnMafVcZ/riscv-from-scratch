#include "Vrv32i_top.h"
#include "verilated.h"
#include <cstdio>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrv32i_top* top = new Vrv32i_top;

    // reset for 5 cycles
    top->reset = 1;
    for (int i = 0; i < 10; i++) {
        top->clk = 0; top->eval();
        top->clk = 1; top->eval();
    }
    top->reset = 0;

    // run for N cycles
    for (int i = 0; i < 10000; i++) {
        top->clk = 0; top->eval();
        top->clk = 1; top->eval();
    }

    if (top->debug_dmem0 == 8)
        printf("PASS: dmem[0] = 8\n");
    else
        printf("FAIL: dmem[0] = %d\n", top->debug_dmem0);

    printf("done\n");
    delete top;
    return 0;
}
