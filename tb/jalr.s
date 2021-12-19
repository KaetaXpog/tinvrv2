# this file test jalr and func call
# r31: link reg
# r1: function arg1
# r2: function arg2
# r3: return value
# r4: res1
# r5: res2
MAIN:
    addi $1,$0,1
    addi $2,$0,2
    jal $31, ADD
    addi $4,$3,0    # 1+2=3
    
    addi $1,$0,3
    addi $2,$0,4
    jal $31, ADD
    addi $5,$3,0    # 3+4=7
    jal $0,END
ADD:
     add $3,$1,$2
    jalr $0,$31,0
END:
    jal $0,END
    addi $0,$0,0
    addi $0,$0,0
    addi $0,$0,0
    addi $0,$0,0
    addi $0,$0,0
    addi $0,$0,0
