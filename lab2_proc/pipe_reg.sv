module pipe_reg #(
    parameter DW = 4,
    parameter RV = 0    // rst value of q
)(
    input clk,
    input rst, en,
    input [DW-1:0] d,
    output logic [DW-1:0] q
);
    always @(posedge clk) begin
        if(rst)
            q<=RV;
        else if(en)
            q<=d;
    end
endmodule
