`include "mem-msgs.v"

module proc_with_cache(
    input clk,
    input reset,

    // From mngr streaming port

    input  logic [31:0]  mngr2proc_msg,
    input  logic         mngr2proc_val,
    output logic         mngr2proc_rdy,

    // To mngr streaming port

    output logic [31:0]  proc2mngr_msg,
    output logic         proc2mngr_val,
    input  logic         proc2mngr_rdy,

    // Instruction Memory Request Port

    output mem_req_16B_t  imemreq_msg,
    output logic         imemreq_val,
    input  logic         imemreq_rdy,

    // Instruction Memory Response Port

    input  mem_resp_16B_t imemresp_msg,
    input  logic         imemresp_val,
    output logic         imemresp_rdy,

    // Data Memory Request Port

    output mem_req_16B_t  dmemreq_msg,
    output logic         dmemreq_val,
    input  logic         dmemreq_rdy,

    // Data Memory Response Port

    input  mem_resp_16B_t dmemresp_msg,
    input  logic         dmemresp_val,
    output logic         dmemresp_rdy,

    // stats output

    output    commit_inst
);
    mem_req_4B_t  icachereq_msg;
    logic         icachereq_val;
    logic         icachereq_rdy;
    mem_resp_4B_t icacheresp_msg;
    logic         icacheresp_val;
    logic         icacheresp_rdy;

    mem_req_4B_t  dcachereq_msg;
    logic         dcachereq_val;
    logic         dcachereq_rdy;
    mem_resp_4B_t dcacheresp_msg;
    logic         dcacheresp_val;
    logic         dcacheresp_rdy;

  // stats output

    logic         commit_inst;

    lab2_proc_ProcAltVRTL u_proc(
    	.clk           (clk           ),
        .reset         (reset         ),
        .mngr2proc_msg (mngr2proc_msg ),
        .mngr2proc_val (mngr2proc_val ),
        .mngr2proc_rdy (mngr2proc_rdy ),
        .proc2mngr_msg (proc2mngr_msg ),
        .proc2mngr_val (proc2mngr_val ),
        .proc2mngr_rdy (proc2mngr_rdy ),
        .imemreq_msg   (icachereq_msg   ),
        .imemreq_val   (icachereq_val   ),
        .imemreq_rdy   (icachereq_rdy   ),
        .imemresp_msg  (icacheresp_msg  ),
        .imemresp_val  (icacheresp_val  ),
        .imemresp_rdy  (icacheresp_rdy  ),
        .dmemreq_msg   (dcachereq_msg   ),
        .dmemreq_val   (dcachereq_val   ),
        .dmemreq_rdy   (dcachereq_rdy   ),
        .dmemresp_msg  (dcacheresp_msg  ),
        .dmemresp_val  (dcacheresp_val  ),
        .dmemresp_rdy  (dcacheresp_rdy  ),
        .commit_inst   (commit_inst   )
    );

    lab3_mem_BlockingCacheAltVRTL u_icache(
    	.clk           (clk           ),
        .reset         (reset         ),
        .cachereq_msg  (icachereq_msg  ),
        .cachereq_val  (icachereq_val  ),
        .cachereq_rdy  (icachereq_rdy  ),
        .cacheresp_msg (icacheresp_msg ),
        .cacheresp_val (icacheresp_val ),
        .cacheresp_rdy (icacheresp_rdy ),
        .memreq_msg    (imemreq_msg    ),
        .memreq_val    (imemreq_val    ),
        .memreq_rdy    (imemreq_rdy    ),
        .memresp_msg   (imemresp_msg   ),
        .memresp_val   (imemresp_val   ),
        .memresp_rdy   (imemresp_rdy   )
    );
    
    lab3_mem_BlockingCacheAltVRTL u_dcache(
    	.clk           (clk           ),
        .reset         (reset         ),
        .cachereq_msg  (dcachereq_msg  ),
        .cachereq_val  (dcachereq_val  ),
        .cachereq_rdy  (dcachereq_rdy  ),
        .cacheresp_msg (dcacheresp_msg ),
        .cacheresp_val (dcacheresp_val ),
        .cacheresp_rdy (dcacheresp_rdy ),
        .memreq_msg    (dmemreq_msg    ),
        .memreq_val    (dmemreq_val    ),
        .memreq_rdy    (dmemreq_rdy    ),
        .memresp_msg   (dmemresp_msg   ),
        .memresp_val   (dmemresp_val   ),
        .memresp_rdy   (dmemresp_rdy   )
    );
    
endmodule
