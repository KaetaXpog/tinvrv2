`ifndef __DEFINES_V
`define __DEFINES_V

`define ALU_ADD 1
`define ALU_SUB 2
`define ALU_AND 3
`define ALU_OR  4
`define ALU_XOR 5
`define ALU_LT  6
`define ALU_LTU 7
`define ALU_SLL 8
`define ALU_SRL 9
`define ALU_SRA 10
`define ALU_OP1 11
`define ALU_OP2 12
`define ALU_EQ  13

`define PC_SEL_P4_F     3
`define PC_SEL_JAL_D    2
`define PC_SEL_BR_X     1
`define PC_SEL_JALR_X   0

`define IMM_GEN_I       0
`define IMM_GEN_S       1
`define IMM_GEN_U       2

`define OP1_SEL_RF0     0
`define OP1_SEL_PC      1

`define OP2_SEL_IMM     0
`define OP2_SEL_RF      1
`define OP2_SEL_CSRR    2

`define CSRR_SEL_CSR    2

// X stage result sel; pc+4 / alu / mul
`define ER_PCI          0
`define ER_A            1
`define ER_M            2

// W stage result sel; alu result or mem result
`define WR_SEL_ALU      0
`define WR_SEL_MEM      1



`endif // __DEFINES_V