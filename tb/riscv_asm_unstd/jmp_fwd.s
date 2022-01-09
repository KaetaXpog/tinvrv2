# sum 1 to 100
# r1 sum
# r2 1;end
# r3 100 -> 1
# r4 link reg
    addi $1,$0,0
    addi $2,$0,1
    addi $3,$0,100
    jal $0,END
    add $1,$1,$3
    addi $3,$3,-1
END:
    jal $0,END  # r1 SHOULD be 0$13ba
