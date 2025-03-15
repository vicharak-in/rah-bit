module mul (
    input                               clk,
    input [RAH_PACKET_WIDTH-1:0]        a,
    input                               empty,

    output reg [RAH_PACKET_WIDTH-1:0]   c = 0,
    output reg                          rden = 0,
    output reg                          wren = 0
);

parameter RAH_PACKET_WIDTH = 48;

localparam IDLE = 3'd0;
localparam NEXT = 3'd1;
localparam LB = 3'd2;
localparam ADD = 3'd3;
localparam WRITE = 3'd4;

reg [RAH_PACKET_WIDTH-1:0] da = 0;
reg [RAH_PACKET_WIDTH-1:0] db = 0;
reg [(2*RAH_PACKET_WIDTH)-1:0] temp_a = 0;
reg r_wait = 0;
reg [1:0] i = 2'd2;
reg [2:0] state = IDLE;

always @(posedge clk) begin
    case(state)
        IDLE: begin
            wren <= 0;
            rden <= 0;

            if (~empty) begin
               rden <= 1;
               state <= NEXT;
            end
        end

        NEXT: begin
            if (r_wait) begin
                da <= a;
                state <= LB;
                r_wait <= 0;
            end else begin
                r_wait <= ~r_wait;
            end
        end

        LB: begin
            db <= a;
            rden <= 0;
            state <= ADD;
        end

        ADD: begin
            temp_a <= da * db;
            state <= WRITE;
        end

        WRITE: begin
            c <= temp_a[(i * 48) - 1 -: 48];
            wren <= 1;

            if (i == 1) begin
                state <= IDLE;
                i <= 2'd2;
            end else begin
                i <= i - 1;
            end
        end
    endcase
end

endmodule
