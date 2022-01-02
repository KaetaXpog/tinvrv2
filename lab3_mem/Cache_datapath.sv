//Cache datapath

`ifndef CACHE_DATAPATH
`define CACHE_DATAPATH

`include "vc/mem-msgs.v"
`include "regs.v"
`include "tagarray.v"
`include "arithmetic.v"
`include "muxes.v"

module Cache_datapath #(
    parameter p_idx_shamt = 0
)(
    //reset signal
    input logic clk,
    input logic reset,

    //cache request
    input mem_req_4B_t cachereq_msg,
    //cache response
    output mem_resp_4B_t cacheresp_msg,
    
    //memory request
    output mem_req_16B_t mem_req_msg,
    //memory response
    input mem_resp_16B_t memresp_msg,

    //cache input register signals
    input logic cachereq_en,
    output logic [2:0] cachereq_type,
    output logic [31:0] cachereq_addr,

    //tag array signals
    input logic tag_array_ren,
    input logic tag_array_wen0,
    input logic tag_array_wen1,
    
    input logic tag_check_en,
    
    input logic [1:0] tag_check_hit,
    output logic [1:0] tag_check_out,
    input logic hit_reg_en,

    output logic tag_match0,
    output logic tag_match1,
    

    //data array signals
    input logic victim,
    input logic victim_sel,
    input logic data_array_ren,
    input logic data_array_wen,
    input logic [15:0] data_array_wben,
    output logic idx_way,

    //write data mux signal and read data reg&mux signals
    input logic write_data_mux_sel,
    input logic read_data_reg_en,
    input logic [2:0] read_word_mux_sel,
    
    //refill request
    input logic memreq_addr_mux_sel,
    input logic [2:0] memreq_type,
    
    input logic memresp_data_reg_en,
    input logic evict_addr_reg_en,

    input logic victim_reg_en
);

    logic rst;
    assign rst=reset;

	localparam TAG_DW = 28;
	localparam TAG_NUM = 8;

    localparam size = 256;                //cache size in bytes
    localparam data_bw = 32;            //data bitwidth
    localparam addr_bw = 32;            //addr bitwidth
    localparam opaque_bw =8;            //opaque bitwidth
    localparam cacheline_bw = 128;            //cacheline bitwidth
    localparam num_block_c = size*8/cacheline_bw;    //number of blocks in the cache
    localparam num_block_w = num_block_c/2;        //number of blocks per way
    localparam idx_bw = $clog2(num_block_w);    //index bitwidth
    localparam offset_bw = $clog2(cacheline_bw/8);  //offset bitwidth
    localparam tag_bw = addr_bw - offset_bw;    //tag bitwidth

    logic [7:0] in_opaque;
    logic [2:0] in_type;
    logic [31:0] in_addr;
    logic [31:0] in_data;

    logic [7:0] out_opaque;
    logic [2:0] out_type;
    logic [31:0] out_addr;
    logic [31:0] out_data;

    assign in_opaque = cachereq_msg[73:66];
    assign in_type      = cachereq_msg[76:74];
    assign in_addr     = cachereq_msg[65:34];
    assign in_data     = cachereq_msg[31:0];


// Configuration  cachereq_msg  registers
//IDLE stage
vc_EnResetReg#(8,0)cachereq_opaque_reg
(
    .clk(clk),
    .reset(reset),
    .en(cachereq_en),
    .d(in_opaque),
    .q(out_opaque)
);

assign cachereq_type = out_type;

vc_EnResetReg#(3,0)cachereq_type_reg
(
    .clk(clk),
    .reset(reset),
    .en(cachereq_en),
    .d(in_type),
    .q(out_type)
);

vc_EnResetReg#(32,0)cachereq_addr_reg
(
    .clk(clk),
    .reset(reset),
    .en(cachereq_en),
    .d(in_addr),
    .q(out_addr)
);

vc_EnResetReg#(32,0)cahcereq_data_reg
(
    .clk(clk),
    .reset(reset),
    .en(cachereq_en),
    .d(in_data),
    .q(out_data)
);

assign cachereq_addr = out_addr;

//TAG_CHECK state
logic [2:0] idx;
logic [3:0] byte_off;

logic [27:0] tag_read_data0;
logic [27:0] tag_read_data1;

logic [27:0] tag_write_data;

assign idx = out_addr[6+p_idx_shamt:4+p_idx_shamt];
assign tag_write_data = out_addr[31:4];


tag_array #(
    .DW  (28  ),
    .NUM (8 )
) u_tag_array0 (
    .clk(clk),
    .rst(reset),
    .read_en(tag_array_ren),
    .read_addr(idx),
    .read_data(tag_read_data0),
    .write_en(tag_array_wen0),
    .write_addr(idx),
    .write_data(tag_write_data)
);

tag_array #(
	.DW  (DW  ),
	.NUM (NUM )
) u_tag_array1 (
    .clk(clk),
    .rst(reset),
    .read_en(tag_array_ren),
    .read_addr(idx),
    .read_data(tag_read_data1),
    .write_en(tag_array_wen1),
    .write_addr(idx),
    .write_data(tag_write_data)
);


//cmp block
logic [27:0] cmp_top_input;
logic [27:0] cmp_bottom_input0;
logic [27:0] cmp_bottom_input1;

assign cmp_top_input             = out_addr[31:4];
assign cmp_bottom_input0 = tag_read_data0;
assign cmp_bottom_input1 = tag_read_data1;

vc_EqComparator#(28)cmp0
(
    .in0(cmp_top_input),
    .in1(cmp_bottom_input0),
    .out(tag_match0)
);

vc_EqComparator#(28)cmp1
(
    .in0(cmp_top_input),
    .in1(cmp_bottom_input1),
    .out(tag_match1)
);

logic [1:0] hit_reg_in;
logic [1:0] hit_reg_out;
assign hit_reg_in = tag_check_hit;

vc_EnResetReg#(2,0)hit_reg
(
    .clk(clk),
    .reset(reset),
    .en(hit_reg_en),
    .d(hit_reg_in),
    .q(hit_reg_out)
);

assign tag_check_out = hit_reg_out;

logic tag_check_reg_out;
vc_EnResetReg#(1,0)tag_check_reg
(
    .clk(clk),
    .reset(reset),
    .en(tag_check_en),
    .d(tag_match1),
    .q(tag_check_reg_out)
);

logic victim_reg_out;
vc_EnResetReg#(1,0)victim_reg
(
    .clk(clk),
    .reset(reset),
    .en(victim_reg_en),
    .d(victim),
    .q(victim_reg_out)
);

//2 bit muxfor the tag_match output and the victim select
vc_Mux2#(1)tag_match_victim_mux
(
    .in0(tag_check_reg_out),
    .in1(victim_reg_out),
    .sel(victim_sel),
    .out(idx_way)
);

//STATE_ININ_DATA_ACCESS
logic [127:0] write_data_mux_top;
logic [127:0] write_data_mux_bottom;
logic [127:0] write_data_mux_output;

assign write_data_mux_top = {4{out_data}};

vc_Mux2#(128)write_data_mux(
    .in0(write_data_mux_bottom),
    .in1(write_data_mux_top),
    .sel(write_data_mux_sel),
    .out(write_data_mux_output)
);

logic [127:0] data_array_read_data;
logic [127:0] data_array_write_data;

assign data_array_write_data = write_data_mux_output;

logic [3:0] data_array_idx;//index for data array
assign data_array_idx = {idx_way, idx};

vc_CombinationalArray_1rw#(128, 16)data_array
(
    .clk(clk),
    .reset(reset),
    .read_en(data_array_ren),
    .read_addr(data_array_idx),
    .read_data(data_array_read_data),
    .write_en(data_array_wen),
    .write_byte_en(data_array_wben),
    .write_addr(data_array_idx),
    .write_data(data_array_write_data)
);

data_array #(
	.DW  (DW  ),
	.NUM (NUM )
)u_data_array(
	.clk           (clk           ),
	.rst           (rst           ),
    .read_en(data_array_ren),
    .read_addr(data_array_idx),
    .read_data(data_array_read_data),
    .write_en(data_array_wen),
    .write_byte_en(data_array_wben),
    .write_addr(data_array_idx),
    .write_data(data_array_write_data)
);


//read_data_regs
logic [127:0] in_read_data;
logic [127:0] out_read_data;
logic [31:0] out_read_word;
assign in_read_data = data_array_read_data;

vc_EnResetReg#(128,0)read_data_reg
(
    .clk(clk),
    .reset(reset),
    .en(read_data_reg_en),
    .d(in_read_data),
    .q(out_read_data)
);

//read word mux
vc_Mux5#(32)read_word_mux
(
    .in0(32'b0),
    .in1(out_read_data[31:0]),
    .in2(out_read_data[63:32]),
    .in3(out_read_data[95:64]),
    .in4(out_read_data[127:96]),
    .sel(read_word_mux_sel),
    .out(out_read_word)
);

//STATE Refill Request Parts for the datapath
logic [31:0] mkaddr;
logic [31:0] memreq_addr_out;

assign mkaddr = {cachereq_addr[31:4], 4'b0000};

vc_Mux2#(32)memreq_addr_mux
(
    .in0(mkaddr),
    .in1(evict_addr_reg_out),
    .sel(memreq_addr_mux_sel),
    .out(memreq_addr_out)
);

assign memreq_msg[127:0] = out_read_data;
assign memreq_msg[131:128] = 4'b0;
assign memreq_msg[163:132] = memreq_addr_out;
assign memreq_msg[171:164] = 8'b0;
assign memreq_msg[174:172] = memreq_type;

//STATE Refill Update
logic [127:0] memresp_data_in;
logic [127:0] memresp_data_out;

assign memresp_data_in = memresp+msg[127:0];

vc_EnResetReg#(128,0)memresp_data_reg
(
    .clk(clk),
    .reset(reset),
    .en(memresp_data_reg_en),
    .d(memresp_data_in),
    .q(memresp_data_out)
);

assign write_data_mux_bottom = memresp_data_out;

//wait stage
assign cacheresp_msg = {cachereq_type, out_opaque, tag_check_out, 2'b0, out_read_word};

//evict stage
logic [31:0] mkaddr_evict;
logic [31:0] evict_addr_reg_out;
assign mkaddr_evict = {evict_addr_mux_out, 4'b0000};

vc_EnResetReg#(32, 0)evict_addr_reg
(
    .clk(clk),
    .reset(reset),
    .en(evict_addr_reg_en),
    .d(mkaddr_evict),
    .q(evict_addr_reg_out)
);
logic [27:0] evict_addr_mux_out;

vc_Mux2#(28)evict_addr_mux
(
    .in0(tag_read_data0),
    .in1(tag_read_data1),
    .sel(victim),
    .out(evict_addr_mux_out)
);

endmodule

`endif 
