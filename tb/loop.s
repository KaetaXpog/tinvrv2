addi x1,x0,55
csrw 0x7c0 ,x1   # expected value 55
_start:
    addi t0, x0, 0x1
    addi t1, x0, 0x0
    addi t3, x0, 0xa
loop:
    add t1, t1, t0
    addi t0, t0, 0x1
    addi t3, t3, -1
    bne t3, x0, loop
    csrw 0x7c0 t1       # give result to mngr to check
NOPS:
    jal x0, NOPS
    nop
    nop
    nop
    nop
    nop
