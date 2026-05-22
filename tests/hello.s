.section .text
.globl _start
_start:
    li x1, 5
    li x2, 3
    add x3, x1, x2
    sw x3, 0(x0)
loop:
    j loop
