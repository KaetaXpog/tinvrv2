`include "defines.v"

module alu(
    input rst,
    input fn,
    input [31:0] op1, op2,
    output logic [31:0] out,
    output logic ops_eq,
    output logic ops_lt,
    output logic ops_ltu
);
    always @(*) begin
        case(fn)
        `ALU_ADD: out=op1+op2;
        `ALU_SUB: out=op1-op2;
        `ALU_AND: out=op1 & op2;
        `ALU_OR : out=op1 | op2;
        `ALU_XOR: out=op1 ^ op2;
        `ALU_LT : out=ops_lt;
        `ALU_LTU: out=ops_ltu;
        `ALU_SLL: out=op1 << op2[4:0];
        `ALU_SRL: out=op1 >> op2[4:0];
        `ALU_SRA: out=$signed(op1) >> op2[4:0];
        `ALU_OP1: out=op1;
        `ALU_OP2: out=op2;
        `ALU_EQ : out=ops_eq;
        default : out=0;
        endcase
    end

    assign ops_eq= op1==op2;
    assign ops_lt= $signed(op1) < $signed(op2);
    assign ops_ltu= op1<op2;
endmodule
