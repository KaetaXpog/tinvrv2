# this asm test branch
# this SHOULD be an inf loop and the 4th inst SHOULD not be executed
addi $1, $0, 5 # 500093
addi $2, $0, 4 # 400113
bne $1,$2, -8  # FE208CE3
addi $3,$0,3
