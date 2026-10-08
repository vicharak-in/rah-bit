module req_queue_gen #(
    parameter NUM_QUEUE  = 4,
    parameter DATA_WIDTH = 41,
    parameter ADDR_WIDTH = 10,
    parameter RAM_DEPTH  = (1 << ADDR_WIDTH)
) (
    input                                  clk,
    input                                  rst,
    output [NUM_QUEUE-1:0]                 empty_flag,
    input  [NUM_QUEUE-1:0 ]                rd_en,
    input  [NUM_QUEUE-1:0]                 Wr_en,
    input  [(NUM_QUEUE * DATA_WIDTH)-1:0 ] data_in,
    output [(NUM_QUEUE * DATA_WIDTH)-1:0]  data_out,
    output [NUM_QUEUE-1:0]                 rd_out
);

genvar i ;
generate
    for (i = 0; i < NUM_QUEUE; i = i + 1) begin

        sync_fifo #(
            .W_DATA     (DATA_WIDTH),
            .W_ADDR     (ADDR_WIDTH)
        ) fifo_inst (
            .empty_o    (empty_flag[i]),
            .clk_i      (clk),
            .wr_en_i    (Wr_en[NUM_QUEUE-i-1]),
            .rd_en_i    (rd_en[i]),
            .wdata      (data_in[(DATA_WIDTH * (NUM_QUEUE - i)) - 1
                            -: DATA_WIDTH]),
            .rdata      (data_out[((DATA_WIDTH *  i)) +: DATA_WIDTH]),
            .a_rst_i    (~rst),
            .rd_valid_o (rd_out[i])
        );
    end
endgenerate

endmodule