`include "vc/mem-msgs.v"

module proc_tb;

    logic         clk;
    logic         rst;

    // From mngr streaming port

    logic [31:0]  mngr2proc_msg;
    logic         mngr2proc_val;
    logic         mngr2proc_rdy;

    // To mngr streaming port

    logic [31:0]  proc2mngr_msg;
    logic         proc2mngr_val;
    logic         proc2mngr_rdy;

    // Instruction Memory Request Port

    mem_req_4B_t  imemreq_msg;
    logic         imemreq_val;
    logic         imemreq_rdy;

    // Instruction Memory Response Port

    mem_resp_4B_t imemresp_msg;
    logic         imemresp_val;
    logic         imemresp_rdy;

    // Data Memory Request Port

    mem_req_4B_t  dmemreq_msg;
    logic         dmemreq_val;
    logic         dmemreq_rdy;

    // Data Memory Response Port

    mem_resp_4B_t dmemresp_msg;
    logic         dmemresp_val;
    logic         dmemresp_rdy;

    // stats 

    logic         commit_inst;

    mngr_if mif(clk,rst);

    lab2_proc_ProcAltVRTL #(
        .p_num_cores (1 )
    )
    u_proc(
        .clk           (clk           ),
        .reset         (rst         ),
        .mngr2proc_msg (mif.mngr2proc_msg ),
        .mngr2proc_val (mif.mngr2proc_val ),
        .mngr2proc_rdy (mif.mngr2proc_rdy ),
        .proc2mngr_msg (mif.proc2mngr_msg ),
        .proc2mngr_val (mif.proc2mngr_val ),
        .proc2mngr_rdy (mif.proc2mngr_rdy ),
        .imemreq_msg   (imemreq_msg   ),
        .imemreq_val   (imemreq_val   ),
        .imemreq_rdy   (imemreq_rdy   ),
        .imemresp_msg  (imemresp_msg  ),
        .imemresp_val  (imemresp_val  ),
        .imemresp_rdy  (imemresp_rdy  ),
        .dmemreq_msg   (dmemreq_msg   ),
        .dmemreq_val   (dmemreq_val   ),
        .dmemreq_rdy   (dmemreq_rdy   ),
        .dmemresp_msg  (dmemresp_msg  ),
        .dmemresp_val  (dmemresp_val  ),
        .dmemresp_rdy  (dmemresp_rdy  ),
        .commit_inst   (commit_inst   )
    );

    ram_wrap imem(
        .clk      (clk      ),
        .rst      (rst      ),
        .req_msg  (imemreq_msg  ),
        .req_val  (imemreq_val  ),
        .req_rdy  (imemreq_rdy  ),
        .resp_msg (imemresp_msg ),
        .resp_val (imemresp_val ),
        .resp_rdy (imemresp_rdy )
    );

    ram_wrap dmem(
        .clk      (clk      ),
        .rst      (rst      ),
        .req_msg  (dmemreq_msg  ),
        .req_val  (dmemreq_val  ),
        .req_rdy  (dmemreq_rdy  ),
        .resp_msg (dmemresp_msg ),
        .resp_val (dmemresp_val ),
        .resp_rdy (dmemresp_rdy )
    );

    initial begin
        clk=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst=1;
        repeat(5) @(posedge clk);
        rst=0;
        mif.getExpectedThenExpect;
    end
    initial begin
        imem.loaddata("code.bin");
        $dumpfile("proc_tb.vcd");
        $dumpvars;
    end

    initial begin
        repeat(4000) @(posedge clk);
        $display("[tb ERROR] timeout");
        $finish;
    end
endmodule 

