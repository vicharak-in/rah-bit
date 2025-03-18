module adder (
    input                               clk,
    input [RAH_PACKET_WIDTH-1:0]        a,
    input                               empty,

    output reg [RAH_PACKET_WIDTH-1:0]   c = 0,
    output reg                          rden = 0,
    output reg                          wren = 0
);

parameter RAH_PACKET_WIDTH = 48;

localparam IDLE = 2'd0;
localparam NEXT = 2'd1;
localparam LB = 2'd2;
localparam ADD = 2'd3;

reg [RAH_PACKET_WIDTH-1:0] da = 0;
reg [RAH_PACKET_WIDTH-1:0] db = 0;
reg r_wait = 0;
reg [1:0] state = IDLE;

always @(posedge clk) begin
    case(state)
        IDLE:begin
            wren <= 0;

            if (~empty) begin
               rden <= 1;
               state <= NEXT;
            end else begin
               rden <= 0;
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
            c <= da + db;
            wren <= 1;
            state <= IDLE;
        end
    endcase
end

endmodule
