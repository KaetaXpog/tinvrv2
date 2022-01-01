`ifndef CACHE_CTRL
`define CACHE_CTRL

module Cache_ctrl
#(
	parameter p_idx_shamt = 0
)
(
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
	input logic [31:0] cachereq_addr

	//tag_match
	input logic tag_match0,
	input logic tag_match1,

	//index
	input logic [2:0] idx
);

`endif // CACHE_CTRL
