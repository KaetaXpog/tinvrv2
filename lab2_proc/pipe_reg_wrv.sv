module pipe_reg_wrv #(
    parameter DW = 4
)(
    input clk,
    input rst, en,
    input [DW-1:0] d,
    output logic [DW-1:0] q,
    input [DW-1:0] rstvalue
);
    always @(posedge clk) begin
        if(rst)
            q<=rstvalue;
        else if(en)
            q<=d;
    end
endmodule
