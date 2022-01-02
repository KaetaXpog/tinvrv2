`ifndef CACHE_CTRL
`define CACHE_CTRL

`include "mem-msgs.v"

module Cache_ctrl #(
	parameter p_idx_shamt = 0
)(
	//reset signal
	input logic clk,
	input logic reset,

	//Cache request 
	input logic cachereq_val,
	output logic cachereq_rdy,

	//Cache response
	output logic cacheresp_val,
	input logic cacheresp_rdy,

	//Memory request
	output logic memreq_val,
	input logic memreq_rdy,

	//Memory response
	input logic memresp_val,
	output logic memresp_rdy,

	//Cache request and memory response interface
	output logic cachereq_en,
	output logic memresp_en,
	
	//Mux signals
	output logic write_data_mux_sel,
	
	//Array enable signals
	output logic tag_array_en,
	output logic tag_array_wen0,
	output logic tag_array_wen1,
	output logic data_array_ren,
	output logic data_array_wen,
	output logic data_array_wben,
	
	//reg enables and mux signals after arrays
	output logic read_data_mux_sel,
	output logic read_data_reg_en,
	output logic evict_addr_reg_en,
	output logic memreq_addr_mux_sel,
	output logic [1:0] read_word_mux_sel,

	//Cache response and memory request interface
	output logic [2:0] cacheresp_type,
	output logic [2:0] memreq_type,
	output logic cacheresp_data_mux_sel,
	output logic mkaddr_mux_sel,
	output logic hit,
	output logic victim,

	//Cache request and memory response interface
	input logic [2:0] cachereq_type,
	
	//Addr signal
	input logic [31:0] cachereq_addr,

	//tag_match
	input logic tag_match0,
	input logic tag_match1,

	//line index
	input logic [2:0] idx
);
	logic rst;
	assign rst=reset;

	localparam S_IDLE = 0;
	localparam S_TAGCHECK = 1;
	localparam S_READACC = 2;
	localparam S_WRITEACC = 3;
	localparam S_WAIT = 4;
	localparam S_REFILLREQ = 5;
	localparam S_REFILLWAIT = 6;
	localparam S_REFILLUPDATE = 7;
	localparam S_EVICTPP = 8;
	localparam S_EVICTREQ = 9;
	localparam S_EVICTWAIT = 10;

	logic [7:0] valid[0:1]; // 2-way 8-block
	logic [7:0] last_use; // last used line, to impl LRU

	logic read_hit;
	logic write_hit;

	logic [3:0] cs;

	assign hit= valid[0][idx] && tag_match0 || valid[1][idx] && tag_match1;
	assign read_hit= hit && cachereq_type==`VC_MEM_REQ_MSG_TYPE_READ;
	assign write_hit = hit && cachereq_type==`VC_MEM_REQ_MSG_TYPE_WRITE;

	always @(posedge clk) begin
		if(rst) cs<=S_IDLE;
		else begin
			case(cs)
			S_IDLE: if(cachereq_val) cs<=S_TAGCHECK;
			S_TAGCHECK: if(read_hit) cs<=S_READACC;
				else if(write_hit) cs<=S_WRITEACC;
				else if // TODO
			default: cs<=S_IDLE;
			endcase
		end
	end

	assign cachereq_rdy= cs==S_IDLE;
endmodule

`endif // CACHE_CTRL
