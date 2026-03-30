module subtractor (
    input                               clk,
    input signed [RAH_PACKET_WIDTH-1:0] a,
    input                               empty,

    output reg signed [RAH_PACKET_WIDTH-1:0] c = 0,
    output reg                          rden = 0,
    output reg                          wren = 0
);

parameter RAH_PACKET_WIDTH = 48;

localparam IDLE   = 2'd0;
localparam LOAD_A = 2'd1;
localparam LOAD_B = 2'd2;
localparam SUBB   = 2'd3;

reg signed [RAH_PACKET_WIDTH-1:0] operand_a = 0;
reg signed [RAH_PACKET_WIDTH-1:0] operand_b = 0;
reg r_wait = 0;
reg [1:0] state = IDLE;

always @(posedge clk) begin
    case(state)
        IDLE:begin
            wren <= 0;

            if (~empty) begin
               rden <= 1;
               state <= LOAD_A;
            end else begin
               rden <= 0;
            end
        end

        LOAD_A: begin

            if (r_wait) begin
                operand_a <= a;
                state <= LOAD_B;
                r_wait <= 0;
            end else begin
                r_wait <= ~r_wait;
            end
        end

        LOAD_B: begin
            operand_b <= a;
            rden <= 0;
            state <= SUBB;
        end

        SUBB: begin
            c <= operand_a - operand_b;
            wren <= 1;
            state <= IDLE;
        end
    endcase
end

endmodule