module data_array #(
    parameter DW = 128,
    parameter NUM = 8
)(
    input clk,
    input rst,

    input read_en,
    input [$clog2(NUM)-1:0] read_addr,
    output logic [DW-1:0] read_data,

    input write_en,
    input [DW/8-1:0] write_byte_en,
    input [$clog2(NUM)-1:0] write_addr,
    input [DW-1:0] write_data
);
    reg [DW-1:0] data [0:NUM-1];

    always @(*) begin
        if(read_en) read_data=data[read_addr];
        else read_data={DW{1'b0}};
    end

    genvar i;
    generate for(i=0;i<DW/8-1;i=i+1) begin
        always @(posedge clk) begin
            if(rst) ;
            else if(write_en) begin
                data[write_addr][i*8+7:i*8]<=write_data[i*8+7:i*8];
            end
        end
    end endgenerate
endmodule
