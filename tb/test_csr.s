# test whether csr inst works here......
# set x1; read x1+42
csrr x1, 0xfc0
addi x2,x1,42
csrw 0x7c0, x2
