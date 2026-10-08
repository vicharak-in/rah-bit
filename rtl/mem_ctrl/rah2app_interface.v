module rah2app_interface (
    /* Clock Signal */
    input                                   clk,

    /* Reset Signal */
    input                                   rst,

    /* Path Select Signal */
    input [1:0]                             path_select,

    /* RAH FIFO Interface signals */
    input                                   rah_fifo_empty,
    input                                   rah_fifo_a_empty,
    input [FIFO_ADD_WIDTH - 1 : 0]          rah_fifo_data_cnt,
    input [RAH_DATA_WIDTH - 1 : 0]          rah_fifo_rd_data,
    output                                  rah_fifo_rd_en,

    /* DRAM Write_Ctrl Signals */
    input                                   buffer_rd_en,
    output                                  buffer_empty,
    output                                  buffer_a_empty,
    output [RAH_DATA_WIDTH - 1 : 0]         buffer_rd_data,

    /* DRAM Read FIFO Signals */
    input                                   dram_fifo_empty,
    input                                   dram_fifo_a_empty,
    input [RAH_DATA_WIDTH - 1 : 0]          dram_fifo_rd_data,
    output reg                              dram_fifo_rd_en,

    /* Bridge FIFO signals */
    input                                   bridge_fifo_prog_full,
    output reg                              bridge_fifo_wr_en,
    output reg [RAH_DATA_WIDTH - 1 : 0]     bridge_fifo_wr_data
);

/* Parameters Declaration */
parameter RAH_DATA_WIDTH = 48;
parameter FIFO_ADD_WIDTH = 10;
parameter THRESHOLD_CNT  = 256;
parameter MARGIN_CNT     = 5;

assign rah_fifo_rd_en = buffer_rd_en || rah_rd_en;
assign buffer_rd_data = rah_fifo_rd_data;
assign buffer_empty = (path_select == 2'b01) ? rah_fifo_empty : r_buffer_empty;
assign buffer_a_empty = (path_select == 2'b01) ? rah_fifo_a_empty
                                        : r_buffer_a_empty;

/* FSM State parameters declaration */ 
reg [1:0] state = 0;
localparam CHECK_FIFO_PROG_FULL = 2'b00;
localparam RD_FROM_RAH_FIFO     = 2'b01;
localparam RD_FROM_DRAM_FIFO    = 2'b10;

/* Internal register declaration */
reg rah_rd_en = 0;
reg dram_rd_en_delay = 0;
reg rd_en_delay = 0;

/* To check whether the overall dram data has been read or not */
wire cnt_match_flag;
assign cnt_match_flag = (rah_rd_total_cnt == bridge_fifo_wr_cnt);

/*  FSM to read data from rah fifo or dram fifo based on 
    data availability and write into bridge fifo */
always@(posedge clk) begin
    if(rst) begin
        state <= CHECK_FIFO_PROG_FULL;
        rah_rd_en <= 0;
        dram_fifo_rd_en <= 0;
        bridge_fifo_wr_en <= 0;
        bridge_fifo_wr_data <= 0;
        dram_rd_en_delay <= 0;
        rd_en_delay <= 0;
    end else begin
        rah_rd_en <= 0;
        dram_fifo_rd_en <= 0;
        bridge_fifo_wr_en <= 0;

        case(state)
            CHECK_FIFO_PROG_FULL : begin
                if(!bridge_fifo_prog_full) begin
                    if(!dram_fifo_empty) begin
                        state <= RD_FROM_DRAM_FIFO;
                    end else if((!rah_fifo_empty) && (!ddr_wr_flag)
                                            && (cnt_match_flag)) begin
                        state <= RD_FROM_RAH_FIFO;
                    end
                end
            end

            RD_FROM_RAH_FIFO : begin
                if(bridge_fifo_prog_full && !rd_en_delay && !rah_rd_en) begin
                    bridge_fifo_wr_en <= 0;
                    state <= CHECK_FIFO_PROG_FULL;
                end else begin
                    rd_en_delay <= rah_rd_en;
                    bridge_fifo_wr_en <= rd_en_delay;
                    bridge_fifo_wr_data <= rah_fifo_rd_data;

                    if((rah_rd_en && rah_fifo_a_empty) ||
                                        bridge_fifo_prog_full) begin
                        rah_rd_en <= 0;
                    end else if(!rah_fifo_empty) begin
                        rah_rd_en <= 1;
                    end
                end
            end

            RD_FROM_DRAM_FIFO : begin
                if(cnt_match_flag) begin
                    bridge_fifo_wr_en <= 0;
                    state <= CHECK_FIFO_PROG_FULL;
                end else begin
                    dram_rd_en_delay <= dram_fifo_rd_en;
                    bridge_fifo_wr_en <= dram_rd_en_delay;
                    bridge_fifo_wr_data <= dram_fifo_rd_data;

                    if((dram_fifo_rd_en && dram_fifo_a_empty)
                                    || bridge_fifo_prog_full) begin
                        dram_fifo_rd_en <= 0;
                    end else if(!dram_fifo_empty) begin
                        dram_fifo_rd_en <= 1;
                    end
                end
            end
        endcase
    end
end

/* Counter logic to count number of reads happen while writing into DRAM */
reg [9:0] rah_2_dram_cnt = 0;

always @(posedge clk) begin
    if (rst)
        rah_2_dram_cnt <= 10'd0;
    else if (buffer_rd_en) begin
        if (rah_2_dram_cnt == (THRESHOLD_CNT - 1))
            rah_2_dram_cnt <= 10'd0;
        else
            rah_2_dram_cnt <= rah_2_dram_cnt + 1'b1;
    end
end

/* Logic to write data into DRAM ctrl fifo while bridge fifo is full */
reg ddr_wr_flag = 0;
reg r_buffer_a_empty = 1;
reg r_buffer_empty = 1;

reg [1:0] wr_state = 0;
localparam WAIT_FOR_THRESHOLD_COUNT = 2'b00;
localparam WRITE_INTO_DRAM          = 2'b01;

always@(posedge clk) begin
    if(rst) begin
        wr_state <= WAIT_FOR_THRESHOLD_COUNT;
        ddr_wr_flag <= 0;
        r_buffer_a_empty <= 1;
        r_buffer_empty <= 1;
    end else if(path_select == 2'b01) begin
        ddr_wr_flag <= 1;
    end else if(path_select == 2'b10) begin
        case(wr_state)
            WAIT_FOR_THRESHOLD_COUNT : begin
                ddr_wr_flag <= 0;
                r_buffer_empty <= 1;
                r_buffer_a_empty <= 1;

                if(rah_fifo_data_cnt >= THRESHOLD_CNT + MARGIN_CNT) begin
                    if(bridge_fifo_prog_full || (rah_rd_total_cnt
                                != bridge_fifo_wr_cnt) && (!rah_rd_en)) begin
                        ddr_wr_flag <= 1;
                        wr_state <= WRITE_INTO_DRAM;
                    end
                end
            end

            WRITE_INTO_DRAM : begin
                if(rah_2_dram_cnt == (THRESHOLD_CNT - 1)) begin
                    r_buffer_empty <= 1;
                    wr_state <= WAIT_FOR_THRESHOLD_COUNT;
                end else if(rah_2_dram_cnt == (THRESHOLD_CNT - 2)) begin
                    r_buffer_a_empty <= 1;
                end else begin
                    r_buffer_empty <= 0;
                    r_buffer_a_empty <= 0;
                end
            end
        endcase
    end else begin
        ddr_wr_flag <= 0;
        r_buffer_empty <= 1;
        r_buffer_a_empty <= 1;
    end
end

/* This is for Debug purpose only */
reg [31:0] bridge_fifo_wr_cnt = 0;
reg [31:0] rah_rd_total_cnt = 0;
reg [31:0] buffer_rd_en_cnt = 0;

always@(posedge clk) begin
    if(bridge_fifo_wr_en) begin
        bridge_fifo_wr_cnt <= bridge_fifo_wr_cnt + 1;
    end

    if(rah_fifo_rd_en) begin
        rah_rd_total_cnt <= rah_rd_total_cnt + 1;
    end

    if(buffer_rd_en) begin
        buffer_rd_en_cnt <= buffer_rd_en_cnt + 1;
    end
end

endmodule