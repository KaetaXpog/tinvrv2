# accumulate 1*1, 2*2, 3*3...n*n
# x1: i, 1..n
# x2: =x1
# x6: i**2
# x3: n
# x4: acc
# x5: FLAG
li x1, 0
add x2,x1,x0
####################################
# some value pairs
# 150   0x115693  
# 10    0x181
# 40    0x567c
li x3, 40
li x5, 0x567c
li x4, 0
csrw 0x7c0, x5
ACC:
    addi x1, x1, 1
    add x2, x1, x0
    mul x6, x1, x2
    add x4,x4,x6
    bne x1,x3,ACC

    csrw 0x7c0, x4
END:
    jal x0, END
    nop
    nop
    nop
    nop
    nop