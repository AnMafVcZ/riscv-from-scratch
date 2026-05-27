.section .text
.globl _start
_start:
    addi x1, x0, 7   # x1 = 7
    nop
    nop
    nop
    sw   x1, 0(x0)   # dmem[0] = 7
    lw   x2, 0(x0)   # x2 = load dmem[0] = 7
    addi x3, x2, 1   # x3 = x2 + 1 = 8  (load-use hazard: x2 used immediately)
    nop
    nop
    nop
    sw   x3, 0(x0)   # dmem[0] = 8
loop:
    j loop
