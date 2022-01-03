//=========================================================================
// Alternative Blocking Cache
//=========================================================================

`ifndef LAB3_MEM_BLOCKING_CACHE_ALT_V
`define LAB3_MEM_BLOCKING_CACHE_ALT_V

`include "vc/mem-msgs.v"

module lab3_mem_BlockingCacheAltVRTL
#(
  parameter p_num_banks  = 1              // Total number of cache banks
)
(
  input  logic           clk,
  input  logic           reset,

  // Cache Request

  input  mem_req_4B_t    cachereq_msg,
  input  logic           cachereq_val,
  output logic           cachereq_rdy,

  // Cache Response

  output mem_resp_4B_t   cacheresp_msg,
  output logic           cacheresp_val,
  input  logic           cacheresp_rdy,

  // Memory Request

  output mem_req_16B_t   memreq_msg,
  output logic           memreq_val,
  input  logic           memreq_rdy,

  // Memory Response

  input  mem_resp_16B_t  memresp_msg,
  input  logic           memresp_val,
  output logic           memresp_rdy
);


	//Cache request 
	logic cachereq_en;	
	logic [2:0] cachereq_type;
	logic [31:0] cachereq_addr;

	//Cache response
	logic [2:0] cacheresp_type;
	logic [1:0] read_word_mux_sel;	

	//Memory request
	logic [2:0] memreq_type;
	logic evict_addr_reg_en;	
	logic memreq_addr_mux_sel;

	//Memory response
	logic memresp_en;
	
	//Mux signals or datapath en
	logic write_data_mux_sel;
	logic read_data_reg_en;	
	
	//line index
	logic [2:0] idx;
	logic hit;
	logic victim_reg_en;
	logic victim;	
	//Array enable signals
	logic tag_array_ren;
	logic tag_array_wen0;
	logic tag_array_wen1;
	logic tag_check_en;
	logic tag_match0;
	logic tag_match1;	

	// victim sel: data array 1->use victim way; 0->use match way
	logic victim_sel;
	logic idx_way;
	logic data_array_way;
	logic data_array_ren;
	logic data_array_wen;
	logic [15:0] data_array_wben;

Cache_ctrl u_Cache_ctrl(
  .clk                 (clk                 ),
  .reset               (reset               ),
  .cachereq_val        (cachereq_val        ),
  .cachereq_rdy        (cachereq_rdy        ),
  .cachereq_en         (cachereq_en         ),
  .cachereq_type       (cachereq_type       ),
  .cachereq_addr       (cachereq_addr       ),
  .cacheresp_val       (cacheresp_val       ),
  .cacheresp_rdy       (cacheresp_rdy       ),
  .cacheresp_type      (cacheresp_type      ),

  .read_word_mux_sel   (read_word_mux_sel   ),
  .memreq_val          (memreq_val          ),
  .memreq_rdy          (memreq_rdy          ),
  .memreq_type         (memreq_type         ),
  .evict_addr_reg_en   (evict_addr_reg_en   ),
  .memreq_addr_mux_sel (memreq_addr_mux_sel ),

  .memresp_val         (memresp_val         ),
  .memresp_rdy         (memresp_rdy         ),
  .memresp_en          (memresp_en          ),
  .write_data_mux_sel  (write_data_mux_sel  ),

  .read_data_reg_en    (read_data_reg_en    ),
  .idx                 (idx                 ),
  .hit                 (hit                 ),
  .victim_reg_en       (victim_reg_en       ),
  .victim              (victim              ),
  .tag_array_ren       (tag_array_ren       ),
  .tag_array_wen0      (tag_array_wen0      ),
  .tag_array_wen1      (tag_array_wen1      ),
  .tag_check_en        (tag_check_en        ),
  .tag_match0          (tag_match0          ),
  .tag_match1          (tag_match1          ),

  .victim_sel          (victim_sel          ),
  .idx_way             (idx_way             ),
  .data_array_way      (data_array_way      ),
  .data_array_ren      (data_array_ren      ),
  .data_array_wen      (data_array_wen      ),
  .data_array_wben     (data_array_wben     )
);

Cache_datapath u_Cache_datapath(
  .clk                 (clk                 ),
  .reset               (reset               ),
  .cachereq_msg        (cachereq_msg        ),
  .cacheresp_msg       (cacheresp_msg       ),
  .memreq_msg          (memreq_msg          ),
  .memresp_msg         (memresp_msg         ),

  .cachereq_en         (cachereq_en         ),
  .cachereq_type       (cachereq_type       ),
  .cachereq_addr       (cachereq_addr       ),

  .tag_array_ren       (tag_array_ren       ),
  .tag_array_wen0      (tag_array_wen0      ),
  .tag_array_wen1      (tag_array_wen1      ),
  .tag_check_en        (tag_check_en        ),
  .tag_match0          (tag_match0          ),
  .tag_match1          (tag_match1          ),
  .tag_hit             (hit             ),

  .victim              (victim              ),
  .victim_sel          (victim_sel          ),
  .data_array_ren      (data_array_ren      ),
  .data_array_wen      (data_array_wen      ),
  .data_array_wben     (data_array_wben     ),
  .idx_way             (idx_way             ),
  .write_data_mux_sel  (write_data_mux_sel  ),
  .read_data_reg_en    (read_data_reg_en    ),
  .read_word_mux_sel   (read_word_mux_sel   ),

  .memreq_addr_mux_sel (memreq_addr_mux_sel ),
  .memreq_type         (memreq_type         ),
  .evict_addr_reg_en   (evict_addr_reg_en   ),

  .memresp_data_reg_en (memresp_data_reg_en )
);


endmodule

`endif
