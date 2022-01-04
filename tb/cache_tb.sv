`include "mem-msgs.v"

module cache_tb;
    logic           clk;
    logic           reset;
    logic           rst;
    assign reset=rst;

    // Memory Request

    mem_req_16B_t   memreq_msg;
    logic           memreq_val;
    logic           memreq_rdy;

    // Memory Response

    mem_resp_16B_t  memresp_msg;
    logic           memresp_val;
    logic           memresp_rdy;

cache_if cif(clk,rst);

lab3_mem_BlockingCacheAltVRTL u_cache(
    .clk           (clk           ),
    .reset         (reset         ),
    .cachereq_msg  (cif.cachereq_msg  ),
    .cachereq_val  (cif.cachereq_val  ),
    .cachereq_rdy  (cif.cachereq_rdy  ),
    .cacheresp_msg (cif.cacheresp_msg ),
    .cacheresp_val (cif.cacheresp_val ),
    .cacheresp_rdy (cif.cacheresp_rdy ),
    .memreq_msg    (memreq_msg    ),
    .memreq_val    (memreq_val    ),
    .memreq_rdy    (memreq_rdy    ),
    .memresp_msg   (memresp_msg   ),
    .memresp_val   (memresp_val   ),
    .memresp_rdy   (memresp_rdy   )
);

ram_x128_wrap u_mem(
    .clk      (clk      ),
    .rst      (rst      ),
    .req_msg  (memreq_msg  ),
    .req_val  (memreq_val  ),
    .req_rdy  (memreq_rdy  ),
    .resp_msg (memresp_msg ),
    .resp_val (memresp_val ),
    .resp_rdy (memresp_rdy )
);

logic [31:0] addr;
logic [127:0] data;

initial begin
  clk=0;
  forever #50 clk=~clk; 
end
initial begin
  cif.resp_reactor();
end
initial begin
  u_mem.loadHexData("cram.hex");
  cif.init();
  rst=1;

  repeat(3) @(posedge clk);
  rst=0;

  repeat(3) @(negedge clk);
  cif.readInSeq();

  repeat(100) @(negedge clk);
  $finish;
end

endmodule
