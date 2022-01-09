interface mngr_if(
    input clk,
    input rst
);
    logic mngr2proc_val;
    logic mngr2proc_rdy;
    logic [31:0] mngr2proc_msg;
    logic proc2mngr_val;
    logic proc2mngr_rdy;
    logic [31:0] proc2mngr_msg;

    reg [31:0] mngr2procReg;
    reg [31:0] proc2mngrReg;


    task setValue(
        input [31:0] value
    );
        @(posedge clk) mngr2procReg<=value;
        $display("[mngr INFO] set: %h", value);
    endtask

    task expected(
        input [31:0] value,
        input logic en_exit=0
    );
        logic got;
        got=0;
        while(~got) @(posedge clk) begin
            if(proc2mngr_val && proc2mngr_rdy) begin
                got=1;
            end
        end
        if(proc2mngr_msg!=value) begin
            $display("[mngr ERROR] expected: %h, got: %h",
                value,proc2mngr_msg);
            repeat(50) @(posedge clk);
            $finish;
        end else begin
            $display("[mngr INFO] got expected: %h",
                proc2mngr_msg);
            if(en_exit) begin
                $display("[mngr INFO] PASS!!!!!");
                repeat(50) @(posedge clk);
                $finish;
            end
        end
    endtask

    task setThenExpect(
        input [31:0] valueSend,
        input [31:0] valueExpect,
        input logic en_exit=0
    );
        setValue(valueSend);
        expected(valueExpect);
    endtask

    task justAdd42;
        setThenExpect('d33,'d33+'d42);
    endtask

    // at the start of program, it give the expeceted value to
    // mngr; at the end of the program, it give the result to
    // mngr; the MNGR compares the expected value with result.
    // with this task, the system can check by itself :)
    task getExpectedThenExpect(
        input en_exit=1
    );
        logic init;
        init=0;
        while (~init) @(posedge clk) begin
            if(proc2mngr_val && proc2mngr_rdy) init=1;
        end
        @(posedge clk);
        $display("[mngr INFO] FLAG: %h", proc2mngrReg);
        expected(proc2mngrReg,en_exit);
    endtask


    assign mngr2proc_val=1;
    assign mngr2proc_msg=mngr2procReg;    

    initial forever @(posedge clk) begin
        if(rst) proc2mngrReg<=0;
        else if(proc2mngr_val && proc2mngr_rdy) begin
            proc2mngrReg<=proc2mngr_msg;
        end
    end
    assign proc2mngr_rdy=1;

endinterface
