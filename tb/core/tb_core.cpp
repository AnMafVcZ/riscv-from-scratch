#include "Vrv32i_top.h"
#include "verilated.h"
#include <cstdio>
#include <cstring>
#include <cstdlib>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrv32i_top* top = new Vrv32i_top;

    int expected = 8;
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "+EXPECTED=", 10) == 0)
            expected = atoi(argv[i] + 10);
    }

    // reset for 10 cycles
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

    if ((int)top->debug_dmem0 == expected)
        printf("PASS: dmem[0] = %d\n", expected);
    else
        printf("FAIL: dmem[0] = %d (expected %d)\n", top->debug_dmem0, expected);

    printf("done\n");
    delete top;
    return 0;
}
