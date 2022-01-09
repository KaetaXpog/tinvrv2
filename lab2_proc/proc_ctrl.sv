`include "vc/mem-msgs.v"
`include "defines.v"
`include "TinyRV2InstVRTL.v"

module proc_ctrl(
  input  logic         clk,
  input  logic         reset,

  // From mngr streaming port

  input  logic [31:0]  mngr2proc_msg,
  input  logic         mngr2proc_val,
  output logic         mngr2proc_rdy,

  // To mngr streaming port

  output logic [31:0]  proc2mngr_msg,
  output logic         proc2mngr_val,
  input  logic         proc2mngr_rdy,

  // Instruction Memory Request Port

  output mem_req_4B_t  imemreq_msg,
  output logic         imemreq_val,
  input  logic         imemreq_rdy,

  // Instruction Memory Response Port

  input  mem_resp_4B_t imemresp_msg,
  input  logic         imemresp_val,
  output logic         imemresp_rdy,

  // Data Memory Request Port

  output mem_req_4B_t  dmemreq_msg,
  output logic         dmemreq_val,
  input  logic         dmemreq_rdy,

  // Data Memory Response Port

  input  mem_resp_4B_t dmemresp_msg,
  input  logic         dmemresp_val,
  output logic         dmemresp_rdy,

  // stats output

  output logic         commit_inst,

  // Control signals
  output logic reg_en_F,
  output logic [1:0] pc_sel_F,

  output logic reg_en_D,
  input logic [31:0] inst_D,
  output logic [2:0] imm_type_D,
  output logic op1_sel_D,
  output logic [1:0] op2_sel_D,
  output logic [1:0] csrr_sel_D,
  output logic imul_req_val_D,
  input imul_req_rdy_D,
  output bypass_waddr_X_rs1_D,
  output bypass_waddr_X_rs2_D,
  output bypass_waddr_M_rs1_D,
  output bypass_waddr_M_rs2_D,
  output bypass_waddr_W_rs1_D,
  output bypass_waddr_W_rs2_D,

  output logic reg_en_X,
  input br_cond_ltu_X,
  input br_cond_lt_X,
  input br_cond_eq_X,
  output logic [3:0] alu_fn_X,
  output [1:0] ex_result_sel_X,
  output dmemreq_type_X,  // 0 for read, 1 for write when dmemreq_val

  input imul_resp_val_X,
  output logic imul_resp_rdy_X,

  output logic reg_en_M,
  output logic wb_result_sel_M,

  output logic reg_en_W,
  output logic stats_en_wen_W,
  output logic [4:0] rf_waddr_W,
  output logic rf_wen_W
);

wire rst=reset;

// KEEP consistency with defines.v macro
localparam op_lw = 'b0000011,
  op_sw='b0100011,
  op_jal='b1101111,
  op_jalr='b1100111;
localparam alu_add = 1,
  alu_sub=2,
  alu_and=3,
  alu_or=4,
  alu_xor=5,
  alu_lt=6,
  alu_ltu=7,
  alu_sll=8,
  alu_srl=9,
  alu_sra=10,
  alu_op1=11,
  alu_op2=12,
  alu_eq=13,
  alu_nop=0;
localparam imm_i = 0,
  imm_s=1,
  imm_u=2,
  imm_0=0,
  imm_b=3,
  imm_j=4;
localparam op1_rf = 0,
  op1_pc=1;
localparam op2_imm = 0,
  op2_rf=1,
  op2_csr=2;
localparam csr_csr = 2;
localparam y = 1,
  n=0;
// x stage result sel
localparam er_p = 0,
  er_a=1,
  er_m=2;
// W stage result sel
localparam wr_a = 0,
  wr_m=1;

// opcode types
logic opcode_branch_D;
logic opcode_jal_D;
logic op_jalr_D;
logic op_mul_D;
logic opcode_branch_X;
logic op_jalr_X;
logic op_mul_X;

wire imemreq_handshake=imemreq_val && imemreq_rdy;
wire imemresp_handshake=imemresp_val && imemresp_rdy;
wire dmemreq_handshake=dmemreq_val && dmemreq_rdy;
wire dmemresp_handshake=dmemresp_val && dmemresp_rdy;

// TODO: squash
logic val_F;
logic val_D;
logic val_X;
logic val_M;
logic val_W;
logic next_val_F;
logic next_val_D;
logic next_val_X;
logic next_val_M;
logic next_val_W;
logic ostall_F;
logic ostall_D;
logic ostall_X;
logic ostall_M;
logic ostall_W;
logic stall_F;
logic stall_D;
logic stall_X;
logic stall_M;
logic stall_W;
logic osquash_D;
logic osquash_X;
logic osquash_M;
logic osquash_W;
logic squash_F;
logic squash_D;
logic squash_X;
logic squash_M;
logic squash_W;

logic pc_redirect_D;
logic [2:0] br_type_D;
logic [3:0] alu_fn_D;
logic [6:0] inst_op_D;
logic [4:0] inst_rs1_D;
logic [4:0] inst_rs2_D;
logic [4:0] inst_rd_D;
logic [`RV2ISA_INST_CSR_NBITS-1:0] inst_csr_D;
logic rf_wen_D;
logic [1:0] ex_result_sel_D;
logic wb_result_sel_D;

logic pc_redirect_X;
logic [1:0] pc_sel_X;
logic [2:0] br_type_X;
logic [6:0] inst_op_X;
logic [4:0] inst_rs1_X;
logic [4:0] inst_rs2_X;
logic [4:0] inst_rd_X;
logic rf_wen_X;
logic [1:0] ex_result_sel_X;
logic wb_result_sel_X;

logic [3:0] alu_fn_M;
logic [6:0] inst_op_M;
logic [4:0] inst_rs1_M;
logic [4:0] inst_rs2_M;
logic [4:0] inst_rd_M;
logic rf_wen_M;

logic [3:0] alu_fn_W;
logic [6:0] inst_op_W;
logic [4:0] inst_rs1_W;
logic [4:0] inst_rs2_W;
logic [4:0] inst_rd_W;

logic ostall_wait_imem_rdy;

logic bypass_waddr_X_rs1_D;
logic bypass_waddr_X_rs2_D;
logic ostall_load_use_X_rs1_D;
logic ostall_load_use_X_rs2_D;
logic ostall_wait_imul_rdy_D;

logic bypass_waddr_M_rs1_D;
logic bypass_waddr_M_rs2_D;
logic bypass_waddr_W_rs1_D;
logic bypass_waddr_W_rs2_D;

logic osquash_j_D;

logic ostall_wait_imul_val_X;
logic osquash_take_branch_X;
logic osquash_jalr_X;


/* STAGE F */
logic expect_inst;
assign expect_inst=!( ~stall_F && imemreq_val && !imemreq_rdy);
pipe_reg #(.DW(1)) pipe_f(
  clk, reset, 1'b1, expect_inst, val_F
);

logic ostall_wait_imem_data_F;
assign ostall_wait_imem_data_F=val_F && !imemresp_val;
assign ostall_F= ostall_wait_imem_data_F;
assign stall_F=( ostall_F || ostall_D || ostall_X || ostall_M || ostall_W);

assign squash_F=val_F && (osquash_D||osquash_X);

assign reg_en_F= val_F && !stall_F || squash_F;
assign next_val_F=val_F && !stall_F && !squash_F;

// pc sel output logic
always @(*) begin
  if(pc_redirect_X)
    pc_sel_F=pc_sel_X;
  else if(pc_redirect_D)
    pc_sel_F=2;
  else
    pc_sel_F=3;
end

// imem access
assign imemreq_val=!rst&&(!stall_F||squash_F) || !val_F;
assign imemresp_rdy=!stall_F||squash_F;

/* STAGE D */
pipe_reg #(.DW(1)) pipe_fd(
  clk, reset, reg_en_D, next_val_F, val_D
);

assign ostall_wait_imul_rdy_D=val_D && !imul_req_rdy_D;
assign ostall_D=ostall_load_use_X_rs1_D || 
  ostall_load_use_X_rs2_D ||
  ostall_wait_imul_rdy_D;
assign stall_D=(ostall_D || ostall_X || ostall_M || ostall_W);

assign osquash_j_D=inst_op_D==op_jal || inst_op_D==op_jalr;
assign osquash_D=val_D && !stall_D && osquash_j_D;
assign squash_D=val_D && osquash_X;

assign reg_en_D=!stall_D || squash_D;
assign next_val_D=val_D && !stall_D && !squash_D;

rv2isa_InstUnpack u_InstUnpack(
  .inst   (inst_D   ),
  .opcode (inst_op_D ),
  .rd     (inst_rd_D     ),
  .rs1    (inst_rs1_D    ),
  .rs2    (inst_rs2_D    ),
  .funct3 ( ),
  .funct7 ( ),
  .csr    (inst_csr_D)
);

assign bypass_waddr_X_rs1_D=val_D && val_X && inst_op_X!=op_lw &&
  rf_wen_X && inst_rs1_D==inst_rd_X;
assign bypass_waddr_M_rs1_D=val_D && val_M && 
  rf_wen_M && inst_rs1_D==inst_rd_M;
assign bypass_waddr_W_rs1_D=val_D && val_W && 
  rf_wen_W && inst_rs1_D==inst_rd_W;

assign bypass_waddr_X_rs2_D=val_D && val_X && inst_op_X!=op_lw &&
  rf_wen_X && inst_rs2_D==inst_rd_X;
assign bypass_waddr_M_rs2_D=val_D && val_M && 
  rf_wen_M && inst_rs2_D==inst_rd_M;
assign bypass_waddr_W_rs2_D=val_D && val_W && 
  rf_wen_W && inst_rs2_D==inst_rd_W;

// TODO: stall when proc need mngr2proc but it's not ready
assign ostall_load_use_X_rs1_D=val_D && val_X && rf_wen_X &&
  inst_rs1_D==inst_rd_X && inst_rd_X!=0 && inst_op_X==op_lw;
assign ostall_load_use_X_rs2_D=val_D && val_X && rf_wen_X &&
  inst_rs2_D==inst_rd_X && inst_rd_X!=0 && inst_op_X==op_lw;

task oid(
    input [3:0] alu_fn,
    input [2:0] imm_type,
    input op1_sel,
    input [1:0] op2_sel,
    input rf_wen,
    input [1:0] er,
    input wr
);
  alu_fn_D=alu_fn;
  imm_type_D=imm_type;
  op1_sel_D=op1_sel;
  op2_sel_D=op2_sel;
  rf_wen_D=rf_wen;

  ex_result_sel_D=er;
  wb_result_sel_D=wr;
endtask

always @(*) begin
  casez(inst_D) //      op      imm   op1     op2   rfw,er wr  
  `RV2ISA_INST_JAL  :oid(alu_add,imm_j,op1_rf,op2_rf ,y,er_p,wr_a);
  `RV2ISA_INST_JALR :oid(alu_add,imm_i,op1_rf,op2_imm,y,er_p,wr_a);
  `RV2ISA_INST_BEQ  :oid(alu_eq ,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_BNE  :oid(alu_eq ,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_BLT  :oid(alu_lt ,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_BGE  :oid(alu_lt ,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_BLTU :oid(alu_ltu,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_BGEU :oid(alu_ltu,imm_b,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_CSRR :oid(alu_op2,imm_i,op1_rf,op2_csr,y,er_a,wr_a);
  `RV2ISA_INST_CSRW :oid(alu_op1,imm_i,op1_rf,op2_rf ,n,er_a,wr_a);
  `RV2ISA_INST_LW   :oid(alu_add,imm_i,op1_rf,op2_imm,y,er_a,wr_m);
  `RV2ISA_INST_SW   :oid(alu_add,imm_s,op1_rf,op2_imm,n,er_a,wr_a);
  `RV2ISA_INST_ADD  :oid(alu_add,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_SUB  :oid(alu_sub,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_AND  :oid(alu_and,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_OR   :oid(alu_or ,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_XOR  :oid(alu_xor,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_SLT  :oid(alu_lt ,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_SRA  :oid(alu_sra,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_SRL  :oid(alu_srl,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_SLL  :oid(alu_sll,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_MUL  :oid(alu_nop,0    ,op1_rf,op2_rf, y,er_m,wr_a);
  `RV2ISA_INST_SLTU :oid(alu_ltu,0    ,op1_rf,op2_rf, y,er_a,wr_a);
  `RV2ISA_INST_ADDI :oid(alu_add,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_ANDI :oid(alu_and,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_ORI  :oid(alu_or ,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_XORI :oid(alu_xor,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_SLTI :oid(alu_lt ,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_SLTIU:oid(alu_ltu,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_SRAI :oid(alu_sra,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_SRLI :oid(alu_srl,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_SLLI :oid(alu_sll,imm_i,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_LUI  :oid(alu_op2,imm_u,op1_rf,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_AUIPC:oid(alu_add,imm_u,op1_pc,op2_imm,y,er_a,wr_a);
  `RV2ISA_INST_NOP  :oid(alu_add,0,    op1_rf,op2_imm,y,er_a,wr_a);
  default           :oid(alu_add,0,    op1_rf,op2_rf ,n,er_a,wr_a);
  endcase
end

// jal logic
assign opcode_jal_D=inst_op_D=='b1101111;
always @(*) begin
  pc_redirect_D=val_D&&opcode_jal_D;
end

// for X stage use
// jalr logic
assign op_jalr_D=inst_op_D=='b1100111 && inst_D[`RV2ISA_INST_FUNCT3]=='b000;
// branch type decode
assign opcode_branch_D=inst_op_D=='b1100011;
always @(*) begin
  if(opcode_branch_D)
    br_type_D=inst_D[`RV2ISA_INST_FUNCT3];
  else
    br_type_D=0;
end

// TODO: imul access
assign op_mul_D=inst_D[`RV2ISA_INST_OPCODE]=='b0110011&&
  inst_D[`RV2ISA_INST_FUNCT3]=='b000&&
  inst_D[`RV2ISA_INST_FUNCT7]=='b0000001;
always @(*) begin
  if(op_mul_D) begin
    imul_req_val_D=!stall_D;
  end else begin
    imul_req_val_D=0;
  end
end

// csrr related logic
logic op_csrw_D;
logic op_csrw_X;
logic op_csrw_M;
logic op_csrw_W;
// mngr->proc interface
assign mngr2proc_rdy=1;
// inner logic
always @(*) begin
  csrr_sel_D=0;
  op_csrw_D=0;
  casez(inst_D)
  `RV2ISA_INST_CSRR: begin
    case(inst_csr_D)
    `RV2ISA_CPR_NUMCORES:csrr_sel_D=0;
    `RV2ISA_CPR_COREID:csrr_sel_D=1;
    `RV2ISA_CPR_MNGR2PROC:csrr_sel_D=2;
    endcase
  end 
  `RV2ISA_INST_CSRW: begin
    op_csrw_D=1;
  end
  endcase
end

/* STAGE X ***************************************************/
pipe_reg #(.DW(1)) pipe_dx(
  clk, reset, reg_en_X, next_val_D, val_X
);

pipe_reg #(.DW(4)) pipe_alu_fn_dx(
  clk, reset, reg_en_X, alu_fn_D, alu_fn_X
);
pipe_reg #(.DW(7)) pipe_op_dx(clk,rst,reg_en_X,inst_op_D,inst_op_X);
pipe_reg #(.DW(15)) pipe_rsAndrd_dx(clk,rst,reg_en_X,{inst_rs1_D,inst_rs2_D,inst_rd_D},
  {inst_rs1_X,inst_rs2_X,inst_rd_X});
pipe_reg #(.DW(1)) pipe_rf_wen_dx(clk,rst,reg_en_X,rf_wen_D,rf_wen_X);
always @(posedge clk) begin
  if(rst) begin
    opcode_branch_X<=0;
    br_type_X<=0;
    op_jalr_X<=0;
    op_mul_X<=0;
    op_csrw_X<=0;

    ex_result_sel_X<=0;
    wb_result_sel_X<=0;
  end else if(reg_en_X) begin
    opcode_branch_X<=opcode_branch_D;
    br_type_X<=br_type_D;
    op_jalr_X<=op_jalr_D;
    op_mul_X<=op_mul_D;
    op_csrw_X<=op_csrw_D;

    ex_result_sel_X<=ex_result_sel_D;
    wb_result_sel_X<=wb_result_sel_D;
  end
end

assign ostall_wait_imul_val_X=val_X && op_mul_X && !imul_resp_val_X;
assign ostall_X=ostall_wait_imul_val_X;
assign stall_X=(ostall_X || ostall_M || ostall_W);

assign osquash_take_branch_X=val_X && opcode_branch_X && pc_redirect_X;
assign osquash_jalr_X=val_X && op_jalr_X && pc_redirect_X;
assign osquash_X=osquash_take_branch_X || osquash_jalr_X;
assign squash_X=0;

assign reg_en_X=!stall_X || squash_X;
assign next_val_X=val_X && !stall_X && !squash_X;

// branch and jal logic
always @(*) begin
  if(opcode_branch_X) begin
    pc_sel_X=1;
    case(br_type_X)
    'b000:pc_redirect_X=br_cond_eq_X;
    'b001:pc_redirect_X=!br_cond_eq_X;
    'b100:pc_redirect_X=br_cond_lt_X;
    'b101:pc_redirect_X=!br_cond_lt_X;
    'b110:pc_redirect_X=br_cond_ltu_X;
    'b111:pc_redirect_X=!br_cond_ltu_X;
    default:pc_redirect_X=0;
    endcase
  end else if(op_jalr_X) begin
    pc_redirect_X=1;
    pc_sel_X=0;
  end else begin
    pc_redirect_X=0;
    pc_sel_X=0;
  end
end

// imul access
assign imul_resp_rdy_X=val_X && !stall_X;

// mem access
assign dmemreq_val=inst_op_X==op_lw || inst_op_X==op_sw;
assign dmemreq_type_X=inst_op_X==op_sw;
assign dmemresp_rdy=1;


/* STAGE M */
pipe_reg #(.DW(1)) pipe_xm(
  clk, reset, reg_en_M, next_val_X, val_M
);

pipe_reg #(.DW(7)) pipe_op_xm(clk,rst,reg_en_M,inst_op_X,inst_op_M);
pipe_reg #(.DW(15)) pipe_rsAndrd_xm(clk,rst,reg_en_M,{inst_rs1_X,inst_rs2_X,inst_rd_X},
  {inst_rs1_M,inst_rs2_M,inst_rd_M});
pipe_reg #(.DW(1)) pipe_rf_wen_xm(clk,rst,reg_en_M,rf_wen_X,rf_wen_M);
always @(posedge clk) begin
  if(rst) begin
    op_csrw_M<=0;

    wb_result_sel_M<=0;
  end else if(reg_en_M) begin
    op_csrw_M<=op_csrw_X;

    wb_result_sel_M<=wb_result_sel_X;
  end
end

assign ostall_M=0;
assign stall_M=(ostall_M || ostall_W);

assign reg_en_M=!stall_M;
assign next_val_M=val_M && !stall_M;


/* STAGE W **************************************************************/
//pipe_reg_wrv #(1) pipe_mw(clk, reset, reg_en_W, val_W, next_val_M, 0);
pipe_reg #(.DW(1)) pipe_mw(
  clk,reset,reg_en_W,next_val_M,val_W
);

pipe_reg #(.DW(7)) pipe_op_mw(clk,rst,reg_en_W,inst_op_M,inst_op_W);
pipe_reg #(.DW(15)) pipe_rsAndrd_mw(clk,rst,reg_en_W,{inst_rs1_M,inst_rs2_M,inst_rd_M},
  {inst_rs1_W,inst_rs2_W,inst_rd_W});
always @(posedge clk) begin
  if(rst) begin
    op_csrw_W<=0;

    rf_wen_W<=0;
  end else if(reg_en_W) begin
    op_csrw_W<=op_csrw_M;

    rf_wen_W<= val_M&&rf_wen_M;
  end
end

assign stall_W=ostall_W;
assign ostall_W=0;

assign next_val_W=val_W && !stall_W;

assign reg_en_W=!stall_W;

// reg file: write back
assign rf_waddr_W=inst_rd_W;

// write csr; we ASSUME that no stats_en here
assign proc2mngr_val=val_W && op_csrw_W;

// ASSUME always enabled here
assign stats_en_wen_W=1;

endmodule
