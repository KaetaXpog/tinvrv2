module tag_array #(
    parameter DW = 28,
    parameter NUM = 8
)(
    input clk,
    input rst,

    input read_en,
    input [$clog2(NUM)-1:0] read_addr,
    output logic [DW-1:0] read_data,

    input write_en,
    input [$clog2(NUM)-1:0] write_addr,
    input [DW-1:0] write_data
);
    reg [DW-1:0] tags [0:NUM-1];

    always @(*) begin
        if(read_en) read_data=tags[read_addr];
        else read_data=0;
    end

    always @(posedge clk) begin
        if(rst) ;
        else if(write_en) tags[write_addr]<=write_data;
    end
endmodule
