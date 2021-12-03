// this regfile WILL NOT bypass wdata to rdata

module regfile(
    input clk, reset,
    input [4:0] raddr0,
    output logic [31:0] rdata0,
    input [4:0] raddr1,
    output logic [31:0] rdata1,
    input wen,
    input [4:0] waddr,
    input [31:0] wdata
);
    logic [31:0] regs[0:31];

    always @(*) begin
        rdata0= (raddr0==0)? 0: regs[raddr0];
        rdata1= (raddr1==0)? 0: regs[raddr1];
    end

    always @(posedge clk) begin
        if(!reset && wen && waddr!=0)
            regs[waddr]<=wdata;
    end

endmodule 