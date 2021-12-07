`include "vc/mem-msgs.v"
`include "defines.v"

module proc_dpath(
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

    // control signals
    input reg_en_F,
    input pc_sel_F,

    input reg_en_D,
    output logic [31:0] inst_D,
    input [1:0] imm_type_D,
    input op1_sel_D,
    input op2_sel_D,
    input csrr_sel_D,
    input imul_req_val_D,
    output imul_req_rdy_D,
    input bypass_waddr_X_rs1_D,
    input bypass_waddr_X_rs2_D,
    input bypass_waddr_M_rs1_D,
    input bypass_waddr_M_rs2_D,
    input bypass_waddr_W_rs1_D,
    input bypass_waddr_W_rs2_D,

    input reg_en_X,
    output br_cond_ltu_X,
    output br_cond_lt_X,
    output br_cond_eq_X,
    input [3:0] alu_fn_X,
    input [1:0] ex_result_sel_X,
    input dmemreq_type_X,

    output imul_resp_val_X,
    input imul_resp_rdy_X,

    input reg_en_M,
    input wb_result_sel_M,

    input reg_en_W,
    input stats_en_wen_W,
    input [4:0] rf_waddr_W,
    input rf_wen_W

);
    wire rst= reset;

    /* STAGE F */
    logic [31:0] pc_reg_F;
    logic [31:0] pc_next_F;
    logic [31:0] pc_F;
    logic [31:0] pc_incr_F;
    logic [31:0] pc_plus4_F;


    /* STAGE D */
    logic [31:0] pc_reg_D;
    logic [31:0] inst_reg_D;
    logic [31:0] imm_gen_D, pc_plus_imm_D;
    logic [31:0] rf_rdata0_D, rf_rdata1_D;
    logic [31:0] op1_rf_bypass_mux_D, op2_rf_bypass_mux_D;
    logic [31:0] op1_sel_mux_D, op2_sel_mux_D;
    logic [31:0] csrr_sel_mux_D;
    logic jal_target_D;


    /* STAGE X */
    logic [31:0] pc_reg_X;
    logic [31:0] br_target_reg_X;
    logic [31:0] op1_reg_X, op2_reg_X;
    logic [31:0] dmem_write_data_reg_X;

    logic [31:0] br_target_X;
    logic [31:0] jalr_target_X;
    logic [31:0] pc_incr_X;
    logic [31:0] alu_out_X;
    logic [31:0] ex_result_sel_mux_X;


    /* STAGE M */
    logic [31:0] pc_reg_M;
    logic [31:0] ex_result_reg_M;

    logic [31:0] wb_result_sel_mux_M;


    /* STAGE W */
    logic [31:0] pc_reg_W;
    logic [31:0] wb_result_reg_W;
    
    logic [31:0] rf_wdata_W;
    logic [31:0] stats_en;


    /* STAGE F */
    always @(posedge clk) begin
        if(reset)
            pc_reg_F<=-4;
        else if(reg_en_F)
            pc_reg_F<=pc_next_F; 
    end

    assign pc_F=pc_reg_F;
    assign pc_incr_F=pc_F+4;
    always @(*) begin
        case(pc_sel_F)
        `PC_SEL_P4_F    : pc_next_F=pc_incr_F;
        `PC_SEL_JAL_D   : pc_next_F=jal_target_D;
        `PC_SEL_BR_X    : pc_next_F=br_target_X;
        `PC_SEL_JALR_X  : pc_next_F=jalr_target_X;
        endcase
    end

    assign imemreq_msg.type_=`VC_MEM_REQ_MSG_TYPE_READ;
    assign imemreq_msg.opaque=0;
    assign imemreq_msg.addr=pc_next_F;
    assign imemreq_msg.len=0;
    assign imemreq_msg.data=0;


    /* STAGE D */
    always @(posedge clk) begin
        if(reset) begin
            pc_reg_D<=0;
            inst_reg_D<=0;
        end else if(reg_en_D)
            pc_reg_D<=pc_F;
            inst_reg_D<=imemresp_msg.data;
    end
    assign inst_D=inst_reg_D;

    regfile u_regfile(
        .clk(clk),
        .reset(reset),
        .raddr0(inst_reg_D[19:15]),
        .rdata0(rf_rdata0_D),
        .raddr1(inst_reg_D[24:20]),
        .rdata1(rf_rdata1_D),
        .wen(),
        .waddr(),
        .wdata()
    );

    always @(*) begin: imm_gen
        case(imm_type_D)
        `IMM_GEN_I: imm_gen_D={{20{inst_D[31]}},inst_D[31:20]};
        `IMM_GEN_S: imm_gen_D={{20{inst_D[31]}},inst_D[31:25],inst_D[11:7]};
        `IMM_GEN_U: imm_gen_D={inst_D[31:12],12'b0};
        endcase
    end
    assign pc_plus_imm_D=imm_gen_D+pc_reg_D;

    always @(*) begin: op1_rf_bypass_mux
        casez({bypass_waddr_X_rs1_D,bypass_waddr_M_rs1_D,bypass_waddr_M_rs1_D})
        'b1??: op1_rf_bypass_mux_D=alu_out_X;
        'b01?: op1_rf_bypass_mux_D=wb_result_sel_mux_M;
        'b001: op1_rf_bypass_mux_D=rf_wdata_W;
        default: op1_rf_bypass_mux_D=rf_rdata0_D;
        endcase
    end
    always @(*) begin: op2_rf_bypass_mux
        casez({bypass_waddr_X_rs2_D,bypass_waddr_M_rs2_D,bypass_waddr_M_rs2_D})
        'b1??: op2_rf_bypass_mux_D=alu_out_X;
        'b01?: op2_rf_bypass_mux_D=wb_result_sel_mux_M;
        'b001: op2_rf_bypass_mux_D=rf_wdata_W;
        default: op2_rf_bypass_mux_D=rf_rdata0_D;
        endcase
    end

    always @(*) begin: op1_sel_mux
        if(op1_sel_D==`OP1_SEL_RF0)
            op1_sel_mux_D=op1_rf_bypass_mux_D;
        else if(op1_sel_D==`OP1_SEL_PC)
            op1_sel_mux_D=pc_reg_D;
    end
    always @(*) begin: op2_sel_mux
        if(op2_sel_D==`OP2_SEL_IMM)
            op2_sel_mux_D=imm_gen_D;
        else if(op2_sel_D==`OP2_SEL_RF)
            op2_sel_mux_D=op2_rf_bypass_mux_D;
        else if(op2_sel_D==`OP2_SEL_CSRR)
            op2_sel_mux_D=csrr_sel_mux_D;
    end
    always @(*) begin: csrr_sel_mux
        if(csrr_sel_D==0)
            ;
        else if(csrr_sel_D==1)
            csrr_sel_mux_D= mngr2proc_msg;
    end


    /* STAGE X */
    pipe_reg #(.DW(32)) pipe_br_target_DX(clk, rst, reg_en_X, pc_plus_imm_D, br_target_reg_X );
    pipe_reg #(.DW(32)) pipe_pc_DX(clk, rst, reg_en_X, pc_reg_D,      pc_reg_X        );
    pipe_reg #(.DW(32)) pipe_op1_DX(clk, rst, reg_en_X, op1_sel_mux_D, op1_reg_X       );
    pipe_reg #(.DW(32)) pipe_op2_DX(clk, rst, reg_en_X, op2_sel_mux_D, op2_reg_X       );
    pipe_reg #(.DW(32)) pipe_dmem_wdata_DX(clk, rst, reg_en_X, rf_rdata1_D, dmemreq_msg.data);

    assign br_target_X= br_target_X;
    assign jalr_target_X=0;

    assign pc_incr_X=pc_reg_X+4;

    alu u_alu(
        .rst(rst),
        .fn(alu_fn_X),
        .op1(op1_reg_X),
        .op2(op2_reg_X),
        .out(alu_out_X),
        .ops_eq(br_cond_eq_X),
        .ops_lt(br_cond_lt_X),
        .ops_ltu(br_cond_ltu_X)
    );

    always @(*) begin: ex_result_sel_mux
        case(ex_result_sel_X)
        0: ex_result_sel_mux_X=pc_incr_X;
        1: ex_result_sel_mux_X=alu_out_X;
        2: ex_result_sel_mux_X=0;
        endcase
    end

    // dmem req
    assign dmemreq_msg.type_=dmemreq_type_X;
    assign dmemreq_msg.opaque=0;
    assign dmemreq_msg.addr=alu_out_X;
    assign dmemreq_msg.len=0;

    /* STAGE M */
    pipe_reg #(.DW(32)) pipe_pc_XM(clk, rst, reg_en_M, pc_reg_X, pc_reg_M);
    pipe_reg #(.DW(32)) pipe_ex_result_XM(clk, rst, reg_en_M, ex_result_sel_mux_X, ex_result_reg_M);

    always @(*) begin: wb_result_sel_mux
        case(wb_result_sel_M)
        `WR_SEL_ALU: wb_result_sel_mux_M=ex_result_reg_M;
        `WR_SEL_MEM: wb_result_sel_mux_M=dmemresp_msg.data;
        endcase
    end

    

    /* STAGE W */
    pipe_reg #(.DW(32)) pipe_pc_MW(clk, rst, reg_en_W, pc_reg_M, pc_reg_W);
    pipe_reg #(.DW(32)) pipe_wb_result_MW(clk, rst, reg_en_W, wb_result_sel_mux_M, wb_result_reg_W);

    assign rf_wdata_W=wb_result_reg_W;
    assign proc2mngr_msg=wb_result_reg_W;
    always @(posedge clk) begin
        if(rst)
            stats_en<=0;
        else if(stats_en_wen_W)
            stats_en<=wb_result_reg_W;
    end


endmodule




