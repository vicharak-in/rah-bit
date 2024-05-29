/* Example module to receive from RAH */
module rah2uart (
    input                           clk,
    input                           data_queue_empty,
    input                           data_queue_almost_empty,
    input [RAH_PACKET_WIDTH-1:0]    data_frame,
    input                           uart_rx_pin,

    output [RAH_PACKET_WIDTH-1:0]   tx_data,
    output                          send_data,
    output reg                      request_data = 0,
    output                          uart_tx_pin
);

parameter RAH_PACKET_WIDTH = 48;
parameter BYTES_IN_PACKET = RAH_PACKET_WIDTH / 8;
parameter UART_DATA_WIDTH = 8;

reg [2:0] state = 0;
reg send_uart = 0;
reg [RAH_PACKET_WIDTH-1:0] rah_data = 0;
reg [$clog2(BYTES_IN_PACKET):0] cnt = 0;
reg [UART_DATA_WIDTH-1:0] uart_byte = 0;

wire uart_tx_done;

always @(posedge clk) begin
    case (state)
        0: begin
            if (~data_queue_empty) begin
                request_data <= 1;
                state <= 1;
            end
        end

        1: begin
            request_data <= 0;
            state <= 2;
        end

        2: begin
            rah_data <= data_frame;
            cnt <= 0;
            state <= 3;
        end

        3: begin
            if (cnt < BYTES_IN_PACKET) begin
                send_uart <= 1;
                uart_byte <= rah_data[(BYTES_IN_PACKET - cnt - 1)
                        * UART_DATA_WIDTH
                        +: UART_DATA_WIDTH];
                state <= 4;
            end else begin
                state <= 0;
            end
        end

        4: begin
            send_uart <= 0;

            if (uart_tx_done) begin
                cnt <= cnt + 1;
                state <= 3;
            end
        end
    endcase
end

uart_tx #(
    .CLKS_PER_BIT(468)
) transmit (
    .i_Rst_L(1'b1),
    .i_Clock(clk),
    .i_TX_DV(send_uart),
    .i_TX_Byte(uart_byte), 
    .o_TX_Active(),
    .o_TX_Serial(uart_tx_pin),
    .o_TX_Done(uart_tx_done)
);

wire [7:0] uart_rx_byte;

uart_rx #(
    .CLOCKS_PER_BIT(468)
) receiver (
    .i_Clock(clk),
    .i_RX_Serial(uart_rx_pin),
    .o_RX_DV(send_data),
    .o_RX_Byte(uart_rx_byte)
);

assign tx_data = {40'h0, uart_rx_byte};

endmodule
