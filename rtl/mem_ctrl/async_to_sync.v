module async_to_sync (
    input                           clk,
    input                           rst,

    /* Async fifo signals */
    input                           async_fifo_empty,
    input                           async_fifo_a_empty,
    input [DATA_WIDTH - 1 : 0]      async_fifo_rd_data,
    output reg                      async_fifo_rd_en,

    /* Sync fifo Signals */
    input                           sync_fifo_rd_en,
    output  [DATA_WIDTH - 1 : 0]    sync_fifo_rd_data,
    output                          sync_fifo_empty,
    output                          sync_fifo_a_empty,
    output  [ADDR_WIDTH - 1 : 0]    sync_fifo_data_cnt
);

/* Parameter Declaration */
parameter DATA_WIDTH = 48;
parameter ADDR_WIDTH = 9;
parameter PROG_FULL = 500;

/* Internal Register Declaration */
reg [DATA_WIDTH - 1 : 0] sync_fifo_wr_data = 0;
reg sync_fifo_wr_en = 0;
reg rd_en_delay = 0;
wire sync_fifo_prog_full;

/* Logic to read data from async fifo and write into sync fifo */
always@(posedge clk) begin
    if(rst) begin
        async_fifo_rd_en <= 0;
        sync_fifo_wr_en <= 0;
        sync_fifo_wr_data <= 0;
    end else begin
        rd_en_delay <= async_fifo_rd_en;
        sync_fifo_wr_en <= rd_en_delay;
        sync_fifo_wr_data <= async_fifo_rd_data;

        if((async_fifo_rd_en && async_fifo_a_empty)
                             || sync_fifo_prog_full) begin
            async_fifo_rd_en <= 0;
        end else if(!async_fifo_empty) begin
            async_fifo_rd_en <= 1;
        end
    end
end

sync_fifo
    #(.W_DATA(DATA_WIDTH),
      .W_ADDR(ADDR_WIDTH),
      .PROG_FULL(PROG_FULL))
    SYNC_FIFO (
    .a_rst_i        (1'b0),
    .clk_i          (clk),
    .wr_en_i        (sync_fifo_wr_en),
    .wdata          (sync_fifo_wr_data),
    .rd_en_i        (sync_fifo_rd_en),
    .rdata          (sync_fifo_rd_data),
    .prog_full_o    (sync_fifo_prog_full),
    .empty_o        (sync_fifo_empty),
    .almost_empty_o (sync_fifo_a_empty),
    .datacount_o    (sync_fifo_data_cnt)
);

endmodule