.section .text
.globl _start
_start:
    addi x1, x0, 1
    addi x2, x0, 1
    beq  x1, x2, target   # branch taken — must flush wrong+1, wrong+2
    addi x3, x0, 99       # wrong: should be flushed
    addi x3, x0, 99       # wrong: should be flushed
target:
    addi x3, x0, 8        # x3 = 8 (correct path)
    nop
    nop
    nop
    sw   x3, 0(x0)        # dmem[0] = 8
loop:
    j loop
