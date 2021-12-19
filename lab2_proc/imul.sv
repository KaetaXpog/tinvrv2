module imul(
    input clk,
    input rst,
    input req_val,
    output logic req_rdy,
    input [63:0] req_msg,

    output logic resp_val,
    input resp_rdy,
    output logic [31:0] resp_msg
);
    // DECLARATIONS
    // CTRL
    parameter SIDLE=0;
    parameter SCALC = 1;
    parameter SDONE = 2;
    logic [1:0] fsm_cs;
    logic fsm_calc_last;

    logic load_en;
    logic shift_en;
    logic acc_en;
    logic res_clear;
    // DPATH
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [31:0] res;
    logic [5:0] shift_cnt;
    logic [2:0] shift_num;
    /*********************************************/

    // CTRL
    always @(posedge clk) begin
        if(rst) begin
            fsm_cs<=SIDLE;
        end else begin
            case(fsm_cs)
            SIDLE: if(req_val&&req_rdy) begin
                fsm_cs<=SCALC;
            end
            SCALC: if(fsm_calc_last) fsm_cs<=SDONE;
            SDONE: if(resp_val && resp_rdy) fsm_cs<=SIDLE;
            default: fsm_cs<=SIDLE;
            endcase
        end
    end
    assign fsm_calc_last= shift_num+shift_cnt>='d32;

    // interface 
    assign req_rdy=fsm_cs==SIDLE;
    assign resp_val=fsm_cs==SDONE;
    assign resp_msg=res;
    // ctrl signals
    assign load_en=fsm_cs==SIDLE && req_val && req_rdy;
    assign res_clear=fsm_cs==SIDLE && req_val && req_rdy;
    assign shift_en=fsm_cs==SCALC && !fsm_calc_last;
    assign acc_en=fsm_cs==SCALC && op_b[0]==1;

    // DPATH
    always @(posedge clk) begin
        if(rst) begin
            shift_cnt<=0;
        end else begin
            if(res_clear) res<=0;
            else if(acc_en) res<=res+op_a;

            if(load_en) begin
                {op_a,op_b} <= req_msg;
                shift_cnt<=0;
            end else if(shift_en) begin
                op_a<= op_a<<shift_num;
                op_b<= op_b>>shift_num;
                shift_cnt <= shift_cnt+shift_num;
            end
        end
    end

    always @(*) begin
        casez(op_b[4:1])
        'b???1: shift_num=1;
        'b??10: shift_num=2;
        'b?100: shift_num=3;
        'b1000: shift_num=4;
        'b0000: shift_num=5;
        default:shift_num=1;
        endcase
    end
endmodule
