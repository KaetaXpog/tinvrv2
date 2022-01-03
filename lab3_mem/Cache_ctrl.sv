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
	output logic cachereq_en,	
	input logic [2:0] cachereq_type,
	input logic [31:0] cachereq_addr,

	//Cache response
	output logic cacheresp_val,
	input logic cacheresp_rdy,
	output logic [2:0] cacheresp_type,
	output logic [1:0] read_word_mux_sel,	

	//Memory request
	output logic memreq_val,
	input logic memreq_rdy,
	output logic [2:0] memreq_type,
	output logic evict_addr_reg_en,	
	output logic memreq_addr_mux_sel,

	//Memory response
	input logic memresp_val,
	output logic memresp_rdy,
	output logic memresp_en,
	
	//Mux signals or datapath en
	output logic write_data_mux_sel,
	output logic read_data_reg_en,	
	
	//line index
	input logic [2:0] idx
	output logic hit,
	output logic victim,	
	//Array enable signals
	output logic tag_array_ren,
	output logic tag_array_wen0,
	output logic tag_array_wen1,
	input logic tag_match0,
	input logic tag_match1,	

	output logic data_array_ren,
	output logic data_array_wen,
	output logic data_array_wben,
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
	logic [7:0] dirty[0:1];
	logic [7:0] last_use; // last used line, to impl LRU

	logic way_num;
	logic read;
	logic write;
	logic read_hit;
	logic write_hit;

	logic [3:0] cs;

	assign read=cachereq_type==`VC_MEM_REQ_MSG_TYPE_READ;
	assign write=cachereq_type==`VC_MEM_REQ_MSG_TYPE_WRITE;
	assign hit= valid[0][idx] && tag_match0 || valid[1][idx] && tag_match1;
	assign read_hit= hit && read;
	assign write_hit = hit && write;	
	assign way_num=tag_match1;
	assign victim = !last_use[idx];

	always @(posedge clk) begin
		if(rst) cs<=S_IDLE;
		else begin
			case(cs)
			S_IDLE: if(cachereq_val) cs<=S_TAGCHECK;
			S_TAGCHECK: if(read_hit) cs<=S_READACC;
				else if(write_hit) cs<=S_WRITEACC;
				else if(!hit && !dirty[victim][idx]) cs<=S_REFILLREQ;
				else if(!hit && dirty[victim][idx]) cs<=S_EVICTPP;
			S_READACC: cs<=S_WAIT;
			S_WRITEACC: cs<=S_WAIT;

			S_REFILLREQ: if(memreq_rdy) cs<=S_REFILLWAIT;
			S_REFILLWAIT: if(memresp_val) cs<=S_REFILLUPDATE;
			S_REFILLUPDATE: if(write) cs<=S_WRITEACC;
				else if(read) cs<=S_READACC;

			S_EVICTPP: cs<=S_EVICTREQ;
			S_EVICTREQ: if(memreq_rdy) cs<=S_EVICTWAIT;
			S_EVICTWAIT: if(memresp_val) cs<=S_REFILLREQ;
			default: cs<=S_IDLE;
			endcase
		end
	end

	assign cachereq_rdy= cs==S_IDLE;
	assign cachereq_en= cachereq_val && cachereq_rdy;

	assign cacheresp_val= cs==S_WAIT;

	assign memreq_val= cs==S_EVICTREQ || cs==S_REFILLREQ;

	assign memresp_rdy= cs==S_REFILLWAIT || cs==S_EVICTWAIT;
	assign memresp_en= memresp_val && memresp_rdy;

	// ctrl signals to datapath
	always @(*) begin
		// TODO: CHECK default value here
		tag_array_ren=0;
		tag_array_wen0=0;
		tag_array_wen1=0;

		data_array_ren=0;
		data_array_wen=0;
		data_array_wben=0;

		write_data_mux_sel=1;
		read_data_reg_en=0;

		evict_addr_reg_en=0;
		memreq_addr_mux_sel=0;
		read_word_mux_sel=0;

		cacheresp_type=0;
		memreq_type=0;
/*
	
	//Mux signals
	//Array enable signals
	//reg enables and mux signals after arrays
	output logic read_data_reg_en,
	output logic evict_addr_reg_en,
	output logic memreq_addr_mux_sel,
	output logic [1:0] read_word_mux_sel,

	//Cache response and memory request interface
	output logic [2:0] cacheresp_type,
	output logic [2:0] memreq_type,
	*/
		write_data_mux_sel=
	end
endmodule

`endif // CACHE_CTRL
