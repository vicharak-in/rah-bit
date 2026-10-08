module fifo_to_fifo_interface (
    input               clk,
    input               rst,

    input               wr_app_fifo_empty,
    input               wr_app_fifo_a_empty,
    input [47:0]        wr_app_fifo_rd_data,
    output reg          wr_app_fifo_rd_en=0,

    input               rd_app_fifo_full,
    output reg          rd_app_fifo_wr_en=0,
    output reg [47:0]   rd_app_fifo_wr_data=0
);

reg data_sample = 0;

/* Logic to fifo to fifo data transfer */
always@(posedge clk) begin
    if(rst) begin
        wr_app_fifo_rd_en <= 0;
        rd_app_fifo_wr_en <= 0;
        rd_app_fifo_wr_data <= 0;
    end else begin
        data_sample <= wr_app_fifo_rd_en;
        rd_app_fifo_wr_en <= data_sample;
        rd_app_fifo_wr_data <= wr_app_fifo_rd_data;

        if((wr_app_fifo_rd_en && wr_app_fifo_a_empty) || rd_app_fifo_full) begin
            wr_app_fifo_rd_en <= 0;
        end else if(!wr_app_fifo_empty) begin
            wr_app_fifo_rd_en <= 1;
        end
    end
end

endmodule