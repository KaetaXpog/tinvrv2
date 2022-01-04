interface cache_if(
    input clk,
    input rst
);
    logic cachereq_val;
    logic cachereq_rdy;
    mem_req_4B_t cachereq_msg;

    logic cacheresp_val;
    logic cacheresp_rdy;
    mem_resp_4B_t cacheresp_msg;

    task init;
        cachereq_val=0;
        cachereq_msg=0;
    endtask
    task readreq(
        input [31:0] addr
    );
        cachereq_val=1;
        cachereq_msg.type_=`VC_MEM_REQ_MSG_TYPE_READ;
        cachereq_msg.opaque=0;
        cachereq_msg.addr=addr;
        cachereq_msg.len=0;
        cachereq_msg.data=0;
    endtask
    task writereq(
        input [31:0] addr,
        input [127:0] data
    );
        cachereq_val=1;
        cachereq_msg.type_=`VC_MEM_REQ_MSG_TYPE_WRITE;
        cachereq_msg.opaque=0;
        cachereq_msg.addr=addr;
        cachereq_msg.len=0;
        cachereq_msg.data=data;
    endtask
    task resp_reactor;
        cacheresp_rdy=1;
        forever @(posedge clk) begin
            if(cacheresp_val && cacheresp_rdy) begin
                $display("[%t]: got resp data: %h",
                    $time,cacheresp_msg.data); 
            end
        end
    endtask
    task readInSeq;
        logic [31:0] len;
        logic [31:0] addr;
        len=3333;
        for(addr=0;addr<len;addr=addr+4) begin
            readreq(addr);

            @(posedge clk);
            while(~cachereq_rdy) @(posedge clk);
            cachereq_val<=0;

            @(negedge clk);
        end
    endtask
endinterface
