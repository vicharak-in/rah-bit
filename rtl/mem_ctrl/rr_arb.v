module rr_arb #(
    parameter N                  = 4,
    parameter NUM_PORTS          = 4,
    parameter PORT_ID_WIDTH      = 4,
    parameter ADDRESS_WIDTH      = 32,
    parameter BURST_LENGTH_WIDTH = 4,
    parameter BIN_WIDTH          = $clog2(NUM_PORTS),
    parameter DATA_WIDTH         = 41
) (
    input		                         clk,
    input		                         rst_an,
    input [N-1:0]	                     req,
    input                                en_pin,
    input [(N*DATA_WIDTH)-1 : 0]         in_data_div,
    output [N-1:0]	                     grant_out,
    output [NUM_PORTS-1 :0]              req_out,
    output [ADDRESS_WIDTH-1 : 0]         o_addr_div,
    output [(BURST_LENGTH_WIDTH-1) : 0]  o_burst_div,
    output [(N-1) : 0]                   o_port_div,
    output                               o_rw_div,
    output [BIN_WIDTH-1 : 0]             rd_sel_binary,
    input [NUM_PORTS-1 : 0]              r_valid,
    output                               valid_req
);

assign grant_out = grant;

reg  [N-1:0]  grant = 0;
reg	 [N-1:0]  rotate_ptr = 0;
wire [N-1:0]  mask_req;
wire [N-1:0]  mask_grant;
wire [N-1:0]  grant_comb;
wire	      no_mask_req;
wire [N-1:0]  nomask_grant;
wire		  update_ptr;
genvar i;

// rotate pointer update logic
assign update_ptr = |grant[N-1:0];

always @ (posedge clk) begin
	if (!rst_an) begin
		rotate_ptr[0] <= 1'b1;
        rotate_ptr[1] <= 1'b1;
    end else if (req == {N{1'b0}}) begin
        rotate_ptr[0] <= 1'b1;
        rotate_ptr[1] <= 1'b1;
    end else if (update_ptr) begin
		// note: N must be at least 2
		rotate_ptr[0] <= grant[N-1];
		rotate_ptr[1] <= grant[N-1] | grant[0];
	end
end

generate
    for (i = 2; i < N; i = i + 1) begin
        always @ (posedge clk) begin
            if (!rst_an) begin
                rotate_ptr[i] <= 1'b1;
            end else if (update_ptr) begin
                rotate_ptr[i] <= grant[N-1] | (|grant[i-1:0]);
            end
        end
    end
endgenerate

// mask grant generation logic
assign mask_req[N-1:0] = req[N-1:0] & rotate_ptr[N-1:0];
assign mask_grant[0] = mask_req[0];

generate
    for (i = 1; i < N; i = i + 1) begin
        assign mask_grant[i] = (~|mask_req[i-1:0]) & mask_req[i];
    end
endgenerate

// non-mask grant generation logic
assign nomask_grant[0] = req[0];

generate
    for (i = 1; i < N; i = i + 1) begin
        assign nomask_grant[i] = (~|req[i-1:0]) & req[i];
    end
endgenerate

// grant generation logic
assign no_mask_req = ~|mask_req[N-1:0];
assign grant_comb[N-1:0] = (mask_grant[N-1:0] | (nomask_grant[N-1:0]
                                      & {N{no_mask_req}}))&{N{en_pin}};

always @ (posedge clk) begin
	if (!rst_an) begin
        grant[N-1:0] <= {N{1'b0}};
    end else begin
        grant[N-1:0] <= grant_comb[N-1:0] & ~grant[N-1:0];
    end 
end

req_manager #(
    .NUM_PORTS      (NUM_PORTS),
    .DATA_WIDTH     (DATA_WIDTH),
    .ADDRESS_WIDTH  (ADDRESS_WIDTH),
    .BURST_WIDTH    (BURST_LENGTH_WIDTH),
    .BIN_WIDTH      (BIN_WIDTH),
    .PORT_ID_WIDTH  (PORT_ID_WIDTH)
) req_manager_inst  (
    .clk            (clk),
    .rst            (rst_an),
    .req_in         (grant_out),
    .rd_sel_binary  (rd_sel_binary),
    .req_out        (req_out),
    .in_data_div    (in_data_div),
    .o_addr_div     (o_addr_div),
    .o_burst_div    (o_burst_div),
    .o_port_div     (o_port_div),
    .o_rw_div       (o_rw_div),
    .rd_valid       (r_valid),
    .valid_req      (valid_req)
);

endmodule