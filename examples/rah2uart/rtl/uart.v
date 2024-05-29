module uart_tx #(
    parameter CLKS_PER_BIT = 50
) (
    input       i_Rst_L,
    input       i_Clock,
    input       i_TX_DV,
    input [7:0] i_TX_Byte,
    output reg  o_TX_Active,
    output reg  o_TX_Serial,
    output reg  o_TX_Done
);

localparam IDLE         = 2'b00;
localparam TX_START_BIT = 2'b01;
localparam TX_DATA_BITS = 2'b10;
localparam TX_STOP_BIT  = 2'b11;

reg [2:0] r_SM_Main;
reg [17:0] r_Clock_Count;
reg [2:0] r_Bit_Index;
reg [7:0] r_TX_Data;

/* Purpose: Control TX state machine */
always @(posedge i_Clock or negedge i_Rst_L) begin
    if (~i_Rst_L) begin
        r_SM_Main <= 3'b000;
    end else begin
        o_TX_Done <= 1'b0;

        case (r_SM_Main)
            IDLE: begin
                o_TX_Serial   <= 1'b1; // Drive Line High for Idle
                r_Clock_Count <= 0;
                r_Bit_Index   <= 0;

                if (i_TX_DV == 1'b1) begin
                    o_TX_Active <= 1'b1;
                    r_TX_Data   <= i_TX_Byte;
                    r_SM_Main   <= TX_START_BIT;
                end else
                    r_SM_Main <= IDLE;
            end // case: IDLE


            /* Send out Start Bit. Start bit = 0 */
            TX_START_BIT: begin
                o_TX_Serial <= 1'b0;

                /* Wait CLKS_PER_BIT-1 clock cycles for start bit to finish */
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1'b1;
                    r_SM_Main     <= TX_START_BIT;
                end else begin
                    r_Clock_Count <= 0;
                    r_SM_Main     <= TX_DATA_BITS;
                end
            end // case: TX_START_BIT


            /* Wait CLKS_PER_BIT-1 clock cycles for data bits to finish */
            TX_DATA_BITS: begin
                o_TX_Serial <= r_TX_Data[r_Bit_Index];

                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1'b1;
                    r_SM_Main     <= TX_DATA_BITS;
                end else begin
                    r_Clock_Count <= 0;

                    /* Check if we have sent out all bits */
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1'b1;
                        r_SM_Main   <= TX_DATA_BITS;
                    end else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= TX_STOP_BIT;
                    end
                end
            end // case: TX_DATA_BITS


            /* Send out Stop bit.  Stop bit = 1 */
            TX_STOP_BIT: begin
                o_TX_Serial <= 1'b1;

                /* Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish */
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1'b1;
                    r_SM_Main     <= TX_STOP_BIT;
                end else begin
                    o_TX_Done     <= 1'b1;
                    r_Clock_Count <= 0;
                    r_SM_Main     <= IDLE;
                    o_TX_Active   <= 1'b0;
                end
            end // case: TX_STOP_BIT

            default: r_SM_Main <= IDLE;
        endcase
    end // else: !if(~i_Rst_L)
end // always @ (posedge i_Clock or negedge i_Rst_L)


endmodule

module uart_rx #(
    parameter CLOCKS_PER_BIT = 5000
) (
    input         i_Clock,
    input         i_RX_Serial,
    output        o_RX_DV,
    output [7:0]  o_RX_Byte
);

parameter IDLE = 3'b000;
parameter RX_START_BIT = 3'b001;
parameter RX_DATA_BITS = 3'b010;
parameter RX_STOP_BIT = 3'b011;
parameter CLEANUP = 3'b100;

reg [17:0] r_Clock_Count;
reg [2:0] r_Bit_Index;
reg [7:0] r_RX_Byte;
reg r_RX_DV;
reg [2:0] r_SM_Main;

always @(posedge i_Clock) begin
    case (r_SM_Main)
        IDLE: begin
            r_RX_DV <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index <= 0;

            if (i_RX_Serial == 1'b0)
                r_SM_Main <= RX_START_BIT;
            else
                r_SM_Main <= IDLE;
        end

        RX_START_BIT: begin
            if (r_Clock_Count == CLOCKS_PER_BIT / 2) begin
                if (i_RX_Serial == 1'b0) begin
                    r_Clock_Count <= 0;
                    r_SM_Main <= RX_DATA_BITS;
                end else
                    r_SM_Main <= IDLE;
            end else begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
                r_SM_Main <= RX_START_BIT;
            end
        end

        RX_DATA_BITS: begin
            if(r_Clock_Count < CLOCKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
                r_SM_Main <= RX_DATA_BITS;
            end else begin
                r_Clock_Count <= 0;
                r_RX_Byte[r_Bit_Index] <= i_RX_Serial;

                if (r_Bit_Index < 7) begin
                    r_Bit_Index <= r_Bit_Index + 1'b1;
                    r_SM_Main <= RX_DATA_BITS;
                end else begin
                    r_Bit_Index <= 0;
                    r_SM_Main <= RX_STOP_BIT;
                end
            end
        end

        RX_STOP_BIT: begin
            if(r_Clock_Count < CLOCKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1'b1;
                r_SM_Main <= RX_STOP_BIT;
            end else begin
                r_RX_DV <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main <= CLEANUP;
            end
        end

        CLEANUP: begin
            r_SM_Main <= IDLE;
            r_RX_DV <= 1'b0;
        end

        default: r_SM_Main <= IDLE;
    endcase
end

assign o_RX_Byte = r_RX_Byte;
assign o_RX_DV = r_RX_DV;

endmodule
