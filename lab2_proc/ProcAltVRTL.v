//=========================================================================
// 5-Stage Simple Pipelined Processor
//=========================================================================

`ifndef LAB2_PROC_PIPELINED_PROC_BASE_V
`define LAB2_PROC_PIPELINED_PROC_BASE_V

`include "vc/mem-msgs.v"

module lab2_proc_ProcAltVRTL
#(
  parameter p_num_cores = 1
)
(
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

  output logic         commit_inst

);

  // control signals
  logic reg_en_F;
  logic pc_sel_F;

  logic reg_en_D;
  logic [31:0] inst_D;
  logic [1:0] imm_type_D;
  logic op1_sel_D;
  logic op2_sel_D;
  logic csrr_sel_D;
  logic imul_req_val_D;
  logic imul_req_rdy_D;

  logic reg_en_X;
  logic br_cond_ltu_X;
  logic br_cond_lt_X;
  logic br_cond_eq_X;
  logic [3:0] alu_fn_X;
  logic [1:0] ex_result_sel_X;
  logic dmemreq_type_X;

  logic imul_resp_val_X;
  logic imul_resp_rdy_X;

  logic reg_en_M;
  logic wb_result_sel_M;

  logic reg_en_W;
  logic stats_en_wen_W;
  logic [4:0] rf_waddr_W;
  logic rf_wen_W;

  logic bypass_waddr_X_rs1_D;
  logic bypass_waddr_X_rs2_D;
  logic bypass_waddr_M_rs1_D;
  logic bypass_waddr_M_rs2_D;
  logic bypass_waddr_W_rs1_D;
  logic bypass_waddr_W_rs2_D;

proc_ctrl u_proc_ctrl(
  .clk             (clk             ),
  .reset           (reset           ),
  .mngr2proc_msg   (mngr2proc_msg   ),
  .mngr2proc_val   (mngr2proc_val   ),
  .mngr2proc_rdy   (mngr2proc_rdy   ),

  .proc2mngr_msg   (   ),
  .proc2mngr_val   (proc2mngr_val   ),
  .proc2mngr_rdy   (proc2mngr_rdy   ),

  .imemreq_msg     (     ),
  .imemreq_val     (imemreq_val     ),
  .imemreq_rdy     (imemreq_rdy     ),

  .imemresp_msg    (imemresp_msg    ),
  .imemresp_val    (imemresp_val    ),
  .imemresp_rdy    (imemresp_rdy    ),

  .dmemreq_msg     (     ),
  .dmemreq_val     (dmemreq_val     ),
  .dmemreq_rdy     (dmemreq_rdy     ),

  .dmemresp_msg    (dmemresp_msg    ),
  .dmemresp_val    (dmemresp_val    ),
  .dmemresp_rdy    (dmemresp_rdy    ),

  .commit_inst     (commit_inst     ),
  .reg_en_F        (reg_en_F        ),
  .pc_sel_F        (pc_sel_F        ),
  .reg_en_D        (reg_en_D        ),
  .inst_D          (inst_D          ),
  .imm_type_D      (imm_type_D      ),
  .op1_sel_D       (op1_sel_D       ),
  .op2_sel_D       (op2_sel_D       ),
  .csrr_sel_D      (csrr_sel_D      ),
  .imul_req_val_D  (imul_req_val_D  ),
  .imul_req_rdy_D  (imul_req_rdy_D  ),

  .bypass_waddr_X_rs1_D(bypass_waddr_X_rs1_D),
  .bypass_waddr_X_rs2_D(bypass_waddr_X_rs2_D),
  .bypass_waddr_M_rs1_D(bypass_waddr_M_rs1_D),
  .bypass_waddr_M_rs2_D(bypass_waddr_M_rs2_D),
  .bypass_waddr_W_rs1_D(bypass_waddr_W_rs1_D),
  .bypass_waddr_W_rs2_D(bypass_waddr_W_rs2_D),

  .reg_en_X        (reg_en_X        ),
  .br_cond_ltu_X   (br_cond_ltu_X   ),
  .br_cond_lt_X    (br_cond_lt_X    ),
  .br_cond_eq_X    (br_cond_eq_X    ),
  .alu_fn_X        (alu_fn_X        ),
  .ex_result_sel_X (ex_result_sel_X ),
  .dmemreq_type_X  (dmemreq_type_X  ),
  .imul_resp_val_X (imul_resp_val_X ),
  .imul_resp_rdy_X (imul_resp_rdy_X ),

  .reg_en_M        (reg_en_M        ),
  .wb_result_sel_M (wb_result_sel_M ),
  .reg_en_W        (reg_en_W        ),
  .stats_en_wen_W  (stats_en_wen_W  ),
  .rf_waddr_W      (rf_waddr_W      ),
  .rf_wen_W        (rf_wen_W        )
);


proc_dpath u_proc_dpath(
  .clk             (clk             ),
  .reset           (reset           ),
  .mngr2proc_msg   (mngr2proc_msg   ),
  .mngr2proc_val   (mngr2proc_val   ),
  .mngr2proc_rdy   (   ),

  .proc2mngr_msg   (proc2mngr_msg   ),
  .proc2mngr_val   (   ),
  .proc2mngr_rdy   (proc2mngr_rdy   ),

  .imemreq_msg     (imemreq_msg     ),
  .imemreq_val     (     ),
  .imemreq_rdy     (imemreq_rdy     ),

  .imemresp_msg    (imemresp_msg    ),
  .imemresp_val    (imemresp_val    ),
  .imemresp_rdy    (    ),

  .dmemreq_msg     (dmemreq_msg     ),
  .dmemreq_val     (     ),
  .dmemreq_rdy     (dmemreq_rdy     ),

  .dmemresp_msg    (dmemresp_msg    ),
  .dmemresp_val    (dmemresp_val    ),
  .dmemresp_rdy    (    ),

  .commit_inst     (     ),
  .reg_en_F        (reg_en_F        ),
  .pc_sel_F        (pc_sel_F        ),
  .reg_en_D        (reg_en_D        ),
  .inst_D          (inst_D          ),
  .imm_type_D      (imm_type_D      ),
  .op1_sel_D       (op1_sel_D       ),
  .op2_sel_D       (op2_sel_D       ),
  .csrr_sel_D      (csrr_sel_D      ),
  .imul_req_val_D  (imul_req_val_D  ),
  .imul_req_rdy_D  (imul_req_rdy_D  ),

  .bypass_waddr_X_rs1_D(bypass_waddr_X_rs1_D),
  .bypass_waddr_X_rs2_D(bypass_waddr_X_rs2_D),
  .bypass_waddr_M_rs1_D(bypass_waddr_M_rs1_D),
  .bypass_waddr_M_rs2_D(bypass_waddr_M_rs2_D),
  .bypass_waddr_W_rs1_D(bypass_waddr_W_rs1_D),
  .bypass_waddr_W_rs2_D(bypass_waddr_W_rs2_D),

  .reg_en_X        (reg_en_X        ),
  .br_cond_ltu_X   (br_cond_ltu_X   ),
  .br_cond_lt_X    (br_cond_lt_X    ),
  .br_cond_eq_X    (br_cond_eq_X    ),
  .alu_fn_X        (alu_fn_X        ),
  .ex_result_sel_X (ex_result_sel_X ),
  .dmemreq_type_X  (dmemreq_type_X  ),
  .imul_resp_val_X (imul_resp_val_X ),
  .imul_resp_rdy_X (imul_resp_rdy_X ),
  .reg_en_M        (reg_en_M        ),
  .wb_result_sel_M (wb_result_sel_M ),
  .reg_en_W        (reg_en_W        ),
  .stats_en_wen_W  (stats_en_wen_W  ),
  .rf_waddr_W      (rf_waddr_W      ),
  .rf_wen_W        (rf_wen_W        )
);

endmodule

`endif