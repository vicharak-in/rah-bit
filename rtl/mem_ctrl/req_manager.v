module req_manager #(
    parameter NUM_PORTS     = 4,
    parameter DATA_WIDTH    = 41,
    parameter ADDRESS_WIDTH = 32,
    parameter BURST_WIDTH   = 4,
    parameter BIN_WIDTH     = $clog2(NUM_PORTS),
    parameter PORT_ID_WIDTH = 4
) (
    input                                   clk,
    input                                   rst,
    input  [NUM_PORTS-1:0]                  req_in,
    output reg [NUM_PORTS-1:0]              req_out = 0,
    input  [(NUM_PORTS*DATA_WIDTH)-1:0]     in_data_div,
    output [ADDRESS_WIDTH-1:0]              o_addr_div,
    output [BURST_WIDTH-1:0]                o_burst_div,
    output [PORT_ID_WIDTH-1:0]              o_port_div,
    output                                  o_rw_div,
    input  [NUM_PORTS-1:0]                  rd_valid,
    output [BIN_WIDTH-1 :0]                 rd_sel_binary,
    output reg                              valid_req = 0
);

reg [7:0] w_data = 0;
reg [7:0] n_ports = 0;
reg  [DATA_WIDTH-1:0] data_sel=0;

assign o_addr_div = data_sel[DATA_WIDTH - 1 : PORT_ID_WIDTH + BURST_WIDTH + 1];
assign o_burst_div = data_sel [DATA_WIDTH - ADDRESS_WIDTH - 1 -: BURST_WIDTH];
assign o_port_div = data_sel [DATA_WIDTH-ADDRESS_WIDTH-BURST_WIDTH-1
                        -: PORT_ID_WIDTH];
assign o_rw_div = data_sel [DATA_WIDTH - ADDRESS_WIDTH - BURST_WIDTH
                        - PORT_ID_WIDTH - 1] & ~r_rw ;

reg r_rw;

always@(posedge clk) begin
    if(!rst) r_rw <= 1'b0;
    else begin
        if(data_sel[DATA_WIDTH - ADDRESS_WIDTH - BURST_WIDTH
                        - PORT_ID_WIDTH - 1] == 1) begin
            r_rw <= ~data_sel[DATA_WIDTH - ADDRESS_WIDTH
                        - BURST_WIDTH - PORT_ID_WIDTH - 1];
        end else begin
            r_rw <= 1'b0;
        end
    end
end

always @(*) begin
    req_out = req_in;
end

//(* syn_use_dsp = "no" *) reg  signed [DATA_WIDTH-1:0] data_sel;

always @(posedge clk) begin
    if(~rst)begin
        valid_req <= 1'b0;
    end else begin
        if(|(rd_valid))begin
            valid_req <= 1'b1;
        end else begin
            valid_req <= 1'b0;
        end
    end
end

integer i=0;

always @(posedge clk) begin
    if(~rst)begin
        data_sel <= 0;
    end else begin
		for(i = 0; i < NUM_PORTS; i = i + 1) begin
			if(rd_valid[i])begin
                data_sel <= in_data_div[DATA_WIDTH *
                        (i[$clog2(NUM_PORTS) - 1 : 0]) +: DATA_WIDTH];
    	    end 
		end
    end
end

endmodule