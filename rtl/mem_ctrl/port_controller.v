module port_controller #(
    parameter ADDR_SEGMENTS       = 4,
    parameter PORT_ID_VALUE       = 0,
    parameter ADDRESS_WIDTH       = 32,
    parameter IN_ADDR             = 8,
    parameter COMBINED_DATA_WIDTH = 41,
    parameter BURST_LENGTH_WIDTH  = 4,
    parameter PORT_ID_WIDTH       = 4
)(
    input                                clk,
    input                                rst,
    input                                valid,
    input                                last,
    input [IN_ADDR-1:0]                  in_address,
    input [BURST_LENGTH_WIDTH-1:0]       in_burst_len,
    input                                in_enable_rw,

    output reg                           o_valid = 0,
    output reg [COMBINED_DATA_WIDTH-1:0] combined_out = 0
);

/* FSM parameter Declaration */
reg [1:0] state = 0;
localparam IDLE             = 2'b00;
localparam TRANSMIT_ADDRESS = 2'b01;
localparam WAIT_DATA        = 2'b10;

wire [PORT_ID_WIDTH-1:0] port_id_temp;

assign port_id_temp = PORT_ID_VALUE;

/* Registers for storing data */
reg  [ADDRESS_WIDTH-1:0] address_reg = 0;
reg  [BURST_LENGTH_WIDTH-1:0]  burst_len_reg = 0;
reg  enable_rw_reg = 0;

/*Separate always block for handling address and valid signal */
always @(posedge clk) begin
    if (!rst) begin
        address_reg <= 0;
    end else begin
        if (valid)begin
            address_reg <= {address_reg[23:0],in_address};
        end
    end
end

always @(posedge clk) begin
    if (!rst) begin
        state <= IDLE;
        burst_len_reg <= 0;
        enable_rw_reg <= 0;
        combined_out <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (valid) begin
                    state <= TRANSMIT_ADDRESS;
                    burst_len_reg <= in_burst_len;
                    enable_rw_reg <= in_enable_rw;
                    o_valid <= 0;
                end else begin
                    o_valid <= 0;
                end
            end

            TRANSMIT_ADDRESS: begin
                if (last) begin
                    o_valid <= 1'b0;
                    state <= WAIT_DATA;
                end
            end

            WAIT_DATA : begin
                o_valid <= 1'b1;
                combined_out <= {address_reg, burst_len_reg,
                            port_id_temp, enable_rw_reg};
                state <= IDLE ;
            end
        endcase
    end
end

endmodule