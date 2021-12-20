`include "vc/mem-msgs.v"

// A 4B aligned, sync-read ram
module ram_wrap(
    input clk,
    input rst,
    input mem_req_4B_t  req_msg,
    input               req_val,
    output logic        req_rdy,

    output mem_resp_4B_t resp_msg,
    output logic        resp_val,
    input               resp_rdy
);
    localparam SIDLE=0,
        SRESP=1;
    logic state;
    logic req_handshake;
    logic [31:0] req_addr;
    logic resp_handshake;

    logic we;

    assign req_handshake=req_val && req_rdy;
    assign resp_handshake=resp_val && resp_rdy;

    always @(posedge clk) begin
        if(rst)
            state<=SIDLE;
        else if(state==SIDLE) begin
            if(req_handshake) state<=SRESP;
        end else if(state==SRESP) begin
            if(resp_handshake && !req_handshake)
                state<=SIDLE;
        end
    end
    assign req_rdy= 1;
    assign resp_val=state==SRESP;


    assign we=req_msg.type_==`VC_MEM_REQ_MSG_TYPE_WRITE;
    always @(posedge clk) begin
        if(req_handshake) begin
            req_addr<=req_msg.addr;
        end
    end

    logic [31:0] ram_rdata;
    sp_ram 
    #(
        .ADDR_WIDTH (32 ),
        .DATA_WIDTH (32 ),
        .NUM_BYTES  (1024  )
    )
    u_sp_ram(
    	.clk     (clk     ),
        .en_i    (!rst && req_val ),
        .addr_i  (req_msg.addr  ),
        .wdata_i (req_msg.data ),
        .rdata_o (ram_rdata ),
        .we_i    (we   ),
        .be_i    (4'hf    )
    );

    always @(*) begin
        resp_msg.type_=`VC_MEM_REQ_MSG_TYPE_READ;
        resp_msg.opaque=0;
        resp_msg.test=0;
        resp_msg.len=0;
        if(rst) begin
            resp_msg.data=0;
        end else begin
            resp_msg.data=ram_rdata;
        end
    end

    task loaddata(
        input string file
    );
        $readmemb(file, u_sp_ram.mem);
    endtask
    
endmodule

