# sum 1 to 100
# r1 sum
# r2 1;end
# r3 100 -> 1
# r4 link reg
    addi x1,x0,0
    addi x2,x0,1
    addi x3,x0,100
    jal x0 END
    add x1,x1,x3
    addi x3,x3,-1
END:
    jal x0,END  # r1 SHOULD be 0x13ba
