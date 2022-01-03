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
	input logic [2:0] idx,
	output logic hit,
	output logic victim_reg_en,
	output logic victim,	
	//Array enable signals
	output logic tag_array_ren,
	output logic tag_array_wen0,
	output logic tag_array_wen1,
	output logic tag_check_en,
	input logic tag_match0,
	input logic tag_match1,	

	// victim sel: data array 1->use victim way; 0->use match way
	output logic victim_sel,
	input logic idx_way,
	input logic data_array_way,
	output logic data_array_ren,
	output logic data_array_wen,
	output logic [15:0] data_array_wben
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

	// TODO: update these regs
	logic [7:0] valid[0:1]; // 2-way 8-block
	logic [7:0] dirty[0:1];
	logic [7:0] last_use; // last used line, to impl LRU

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
	assign victim = !last_use[idx];

	always @(posedge clk) begin
		if(rst) begin 
			cs<=S_IDLE;
			valid[0]<=0;
			valid[1]<=0;
			dirty[0]<=0;
			dirty[1]<=0;
			last_use<=0;
		end else begin
			case(cs)
			S_IDLE: if(cachereq_val) cs<=S_TAGCHECK;
			S_TAGCHECK: if(read_hit) cs<=S_READACC;
				else if(write_hit) cs<=S_WRITEACC;
				else if(!hit && !dirty[victim][idx]) cs<=S_REFILLREQ;
				else if(!hit && dirty[victim][idx]) cs<=S_EVICTPP;
			S_READACC: begin 
				cs<=S_WAIT;
				last_use[idx]=idx_way;
			end
			S_WRITEACC: begin
				cs<=S_WAIT;
				dirty[idx_way]<=1;
				last_use[idx]<=idx_way;
			end
			S_WAIT: if(cacheresp_rdy) cs<=S_IDLE;

			S_REFILLREQ: if(memreq_rdy) cs<=S_REFILLWAIT;
			S_REFILLWAIT: if(memresp_val) cs<=S_REFILLUPDATE;
			S_REFILLUPDATE: begin
				if(write) cs<=S_WRITEACC;
				else if(read) cs<=S_READACC;

				valid[idx_way][idx]<=1;
				dirty[idx_way][idx]<=0;
			end
			S_EVICTPP: begin 
				cs<=S_EVICTREQ;
				valid[idx_way][idx]<=0;
			end
			S_EVICTREQ: if(memreq_rdy) cs<=S_EVICTWAIT;
			S_EVICTWAIT: if(memresp_val) cs<=S_REFILLREQ;
			default: cs<=S_IDLE;
			endcase
		end
	end

	assign cachereq_rdy= cs==S_IDLE;
	assign cachereq_en= cachereq_val && cachereq_rdy;

	assign cacheresp_val= cs==S_WAIT;

	// ctrl signals to datapath
	always @(*) begin
		// TODO: CHECK default value here
		// TODO: check way selection
		tag_check_en=0;
		tag_array_ren=0;
		tag_array_wen0=0;
		tag_array_wen1=0;

		victim_reg_en=0;
		victim_sel=0;
		data_array_ren=0;
		data_array_wen=0;
		data_array_wben=0;

		write_data_mux_sel=1;
		read_data_reg_en=0;

		evict_addr_reg_en=0;
		memreq_addr_mux_sel=0;
		read_word_mux_sel=0;

		cacheresp_type=0;

		memreq_val=0;
		memreq_type=0;

		case(cs)
		S_TAGCHECK: begin
			tag_array_ren=1;
			tag_check_en=1;	// store match info
			victim_reg_en=1; // store victim info
		end
		S_READACC: begin
			victim_sel=0;	// use the matched way
			data_array_ren=1;
			read_data_reg_en=1;
		end
		S_WRITEACC: begin
			victim_sel=0;
			write_data_mux_sel=1;	// use cachereq data
			data_array_wen=1;
			data_array_wben=16'hf;
		end
		S_WAIT: begin
			if(read) begin
				read_word_mux_sel=cachereq_addr[3:2];
				cacheresp_type=`VC_MEM_REQ_MSG_TYPE_READ;
			end else if(write) begin
				cacheresp_type=`VC_MEM_REQ_MSG_TYPE_WRITE;
			end
		end
		S_REFILLREQ: begin
			memreq_val=1;
			memreq_type=`VC_MEM_REQ_MSG_TYPE_READ;
		end
		S_REFILLWAIT: begin
			memresp_rdy=1;
			if(memresp_val) memresp_en=1;
		end
		S_REFILLUPDATE: begin
			write_data_mux_sel=0;	// sel memresp
			victim_sel=1;
			data_array_wen=1;
			data_array_wben=16'hf;
		end
		S_EVICTPP: begin
			victim_sel=1;
			data_array_ren=1;
			read_data_reg_en=1;
		end
		S_EVICTREQ: begin
			memreq_val=1;
			memreq_type=`VC_MEM_REQ_MSG_TYPE_WRITE;
		end
		S_EVICTWAIT: begin
			memresp_rdy=1;
		end

		endcase
	end
endmodule

`endif // CACHE_CTRL
