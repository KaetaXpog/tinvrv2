# load and save word
# $1 data, $2 addr
addi $1,$0,36
addi $2,$0,4
sw $2,$1,0          # store r1,0x24 value into mem[r2]
lw $3,$2,0          # load mem[r2+0] data into r3
add $4,$1,$3        # this also test load-use stall

# the results
# r1 <- 0x24
# r2 <- 0x4
# r3 <- 0x24
# r4 <- 0x48
