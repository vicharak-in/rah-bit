module port_ctrl_gen #(
    parameter NUM_PORTS           = 4,
    parameter PORT_ID             = {4'b0000, 4'b0001, 4'b0010, 4'b0011},
    parameter ADDRESS_WIDTH       = 32,
    parameter IN_ADDR             = 8,
    parameter COMBINED_DATA_WIDTH = 41,
    parameter BURST_LENGTH_WIDTH  = 4,
    parameter PORT_ID_WIDTH       = 4
) (
    input                                            clk,
    input                                            rst,
    input [NUM_PORTS-1:0]                            valid,
    input [NUM_PORTS-1:0]                            last,
    input [(NUM_PORTS * IN_ADDR)-1:0]                in_address,
    input [(NUM_PORTS * BURST_LENGTH_WIDTH)-1:0]     in_burst_len,
    input [NUM_PORTS-1:0]                            in_enable_rw,
    output [NUM_PORTS-1 : 0]                         o_valid,
    output [(COMBINED_DATA_WIDTH * NUM_PORTS)-1 : 0] combined_out
);

// Generate block to instantiate multiple instances of Port_controller
genvar i;
generate
    for (i = 0; i < NUM_PORTS; i = i + 1) begin
        port_controller #(
            .PORT_ID_VALUE      (PORT_ID[(PORT_ID_WIDTH * (NUM_PORTS - i))-1
                        -: PORT_ID_WIDTH]),
            .ADDR_SEGMENTS      (4),
            .ADDRESS_WIDTH      (ADDRESS_WIDTH),
            .IN_ADDR            (IN_ADDR),
            .COMBINED_DATA_WIDTH(COMBINED_DATA_WIDTH),
            .BURST_LENGTH_WIDTH (BURST_LENGTH_WIDTH),
            .PORT_ID_WIDTH      (PORT_ID_WIDTH)
        ) Port_controller_inst  (
            .clk                (clk),
            .rst                (rst),
            .valid              (valid[NUM_PORTS-i-1]),
            .last               (last[NUM_PORTS-i-1]),
            .in_address         (in_address[(IN_ADDR * (NUM_PORTS - i))-1
                        -: IN_ADDR]),
            .in_enable_rw       (in_enable_rw[NUM_PORTS-i-1]),
            .in_burst_len       (in_burst_len[(BURST_LENGTH_WIDTH *
                       (NUM_PORTS - i))- 1 -: BURST_LENGTH_WIDTH]),
            .o_valid            (o_valid[NUM_PORTS-i-1]),
            .combined_out       (combined_out [(COMBINED_DATA_WIDTH *
                        (NUM_PORTS - i))-1 -: COMBINED_DATA_WIDTH])
        );
    end
endgenerate

endmodule