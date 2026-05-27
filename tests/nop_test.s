.section .text
.globl _start
_start:
    addi x1, x0, 8   # x1 = 8
    nop
    nop
    nop
    sw x1, 0(x0)     # dmem[0] = 8
loop:
    j loop
