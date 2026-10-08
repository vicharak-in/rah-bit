module rd_rqst_ctrl #(
    parameter AXI_BYTES         = 16,
    parameter BURST_LEN_WIDTH   = 8,
    parameter ADDR_CHUNCK_WIDTH = 8,
    parameter AXI_DATA_WIDTH    = 128,
    parameter FIFO_DATA_WIDTH   = 48,
    parameter FIFO_DEPTH        = 256,
    parameter FIFO_OCC_WIDTH    = 8
  )(
    /* System Clock Signal */
    input                                      clk,

    /* System reste Signal */
    input                                      rst_n,

    /* Start and Stop addresses of DRAM */
    input [31:0]                               start_addr,
    input [31:0]                               stop_addr,

    /* Axi rd signals and handshake signals from mem_wr_ctrl */
    input                                      last_data,
    input                                      rvalid,
    input                                      select_rd,
    input                                      rd_start,
    input [31:0]                               write_counter,
    output reg                                 read_done,

    /* Signals from WR side and Rd side fifo's (128-bit) */
    input [FIFO_OCC_WIDTH - 1 : 0]             wr_fifo_occ,
    input [FIFO_OCC_WIDTH - 1 : 0]             rd_fifo_occ,

    /* Signals from Mem_Rd_ctrl module */
    input                                      data_valid,
    input [127:0]                              header_data,

    /* Read request signals to port controller */
    output reg [(BURST_LEN_WIDTH - 1):0]       burst_length,
    output reg [(ADDR_CHUNCK_WIDTH - 1):0]     addr_out,
    output reg                                 rw_enable,
    output reg                                 last,
    output reg                                 valid,

    /* Dram to 128-bit fifo interface signals */
    input                                      fifo_128_empty,
    input [AXI_DATA_WIDTH - 1 :0]              fifo_128_data_in,
    input                                      fifo_128_a_full,
    output reg                                 fifo_128_rd_en,

    /* Rah out interface FIFO (final stage fifo - 48-bit) */
    input                                      rah_fifo_full,
    input                                      rah_out_prog_full,
    output reg                                 rah_fifo_wr_en,
    output reg [FIFO_DATA_WIDTH - 1 :0]        rah_fifo_wr_data
);

assign space_left = (stop_addr - nxt_addr) >> 4;
assign fifo_occ_flag = ((wr_fifo_occ < 100) || (rd_fifo_occ < 100));
assign fifo_space_flag = (((FIFO_DEPTH - rd_fifo_occ) > burst_length)
                        && (!fifo_128_a_full));

/* Internal Registers */
reg [31:0]  current_addr = 0;
reg [31:0]  nxt_addr = 0;
reg [ 3:0]  count_addr_out = 0;
reg [127:0] data_reg = 0;
reg [31:0]  rd_counter = 0;
reg         h_read = 0;
wire        fifo_occ_flag;
wire        fifo_space_flag;
wire [31:0] space_left;

/* Declaration of FSM parameters */
reg [ 3:0] state    = 0;
parameter CHECK_FOR_RD_START     = 4'b0000;
parameter CHECK_FOR_COUNTER      = 4'b0001;
parameter LOAD_DATA_TO_RQST      = 4'b0010;
parameter CHECK_FOR_FIFO_SPACE   = 4'b0011;
parameter GENERATE_REQUEST       = 4'b0100;
parameter WAIT_FOR_DATA_VALID    = 4'b0101;
parameter WAIT_FOR_RD_LAST       = 4'b0110;
parameter CHECK_FOR_FIFO_OCC     = 4'b0111;
parameter CHECK_ADDRESS          = 4'b1000;
parameter UPDATE_ADDRESS         = 4'b1001;

/* Generates Read request and Reads data based on Wr_counter */
always @(posedge clk) begin
    if (!rst_n) begin
        burst_length <= 0;
        addr_out <= 0;
        rw_enable <= 0;
        last <= 0;
        valid <= 0;
        state <= CHECK_FOR_RD_START;
        count_addr_out <= 0;
        nxt_addr <= 0;
        current_addr <= 0;
        h_read <= 0;
        data_reg <= 0;
        rd_counter <= 0;
    end else begin
        case(state)
            CHECK_FOR_RD_START: begin
                rw_enable <= 0;
                last <= 0;
                valid <= 0;
                addr_out <= 0;

                if (rd_start) begin
                    nxt_addr <= start_addr;
                    state <= CHECK_FOR_COUNTER;
                end
            end

            CHECK_FOR_COUNTER : begin
                if(space_left <= 32'd2) begin
                    nxt_addr <= start_addr;
                end else if (write_counter != 0) begin
                    h_read <= 1;
                    state <= LOAD_DATA_TO_RQST;
                end
            end

            LOAD_DATA_TO_RQST : begin
                current_addr <= nxt_addr;
                state <= CHECK_FOR_FIFO_SPACE;

                if (h_read) begin
                    burst_length <= 0;
                end else begin
                    burst_length <= (data_reg[23:16] - 1);
                end
            end

            CHECK_FOR_FIFO_SPACE: begin
                if (fifo_space_flag) begin
                    state <= GENERATE_REQUEST;
                end
            end

            GENERATE_REQUEST: begin
                addr_out <= current_addr[32 - (count_addr_out * 8) - 1 -: 8];
                valid <= 1;
                rw_enable <= 0;
                burst_length <= burst_length;

                if (count_addr_out < 3) begin
                    count_addr_out <= count_addr_out + 1;
                    last <= 0;
                end else begin
                    count_addr_out <= 0;
                    burst_length <= burst_length;
                    last <= 1;

                    if (h_read) begin
                        state <= WAIT_FOR_DATA_VALID;
                    end else begin
                        state <= WAIT_FOR_RD_LAST;
                    end
                end
            end

            WAIT_FOR_DATA_VALID : begin
                last <= 0;
                valid <= 0;
                addr_out <= addr_out;
                burst_length <= burst_length;

                if (data_valid) begin
                    nxt_addr <= (current_addr + ((burst_length + 1)
                                << $clog2(AXI_BYTES)));
                    state <= UPDATE_ADDRESS;
                end
            end

            UPDATE_ADDRESS : begin
                h_read <= 0;
                data_reg <= header_data;
                state <= LOAD_DATA_TO_RQST;

                if (nxt_addr == stop_addr) begin
                    nxt_addr <= start_addr;
                end
            end

            WAIT_FOR_RD_LAST : begin
                last <= 0;
                valid <= 0;
                addr_out <= addr_out;
                burst_length <= burst_length;

                if (last_data && rvalid && select_rd) begin
                    nxt_addr <= (current_addr + ((burst_length + 1)
                                << $clog2(AXI_BYTES)));
                    rd_counter <= rd_counter + 1;
                    read_done <= 1;
                    state <= CHECK_ADDRESS;
                end
            end

            CHECK_ADDRESS : begin
                read_done <= 0;
                state <= CHECK_FOR_FIFO_OCC;

                if (nxt_addr == stop_addr) begin
                    nxt_addr <= start_addr;
                end
            end

            CHECK_FOR_FIFO_OCC : begin
                read_done <= 0;

                if (fifo_occ_flag) begin
                    state <= CHECK_FOR_COUNTER;
                end
            end
        endcase
    end
end

/* Logic to read data from 128-bit fifo */
reg mask_flag = 0;
reg data_flag = 0;
reg [7:0] rd_cnt = 0;
reg [7:0] buf_cnt = 0;
reg [7:0] wr_cnt = 0;
reg wr_done_flag = 0;

reg [1:0] rd_state = 0;
localparam CHECK_EMPTY  = 2'b00;
localparam HOLD         = 2'b01;
localparam HEADER       = 2'b10;
localparam DATA         = 2'b11;

always@(posedge clk) begin
    if(!rst_n) begin
        fifo_128_rd_en <= 0;
        rd_cnt <= 0;
        data_flag <= 0;
        buf_cnt <= 0;
        mask_flag <= 0;
        rd_state <= CHECK_EMPTY;
    end
    else begin
        case(rd_state)
            CHECK_EMPTY : begin
                fifo_128_rd_en <= 0;
                data_flag <= 0;
                buf_cnt <= 0;

                if(!fifo_128_empty) begin
                    fifo_128_rd_en <= 1;
                    rd_state <= HOLD;
                end
            end

            HOLD : begin
                fifo_128_rd_en <= 0;

                if(data_flag) begin
                    rd_cnt <= rd_cnt - 1;
                    buf_cnt <= buf_cnt + 1;
                    rd_state <= DATA;
                end
                else begin
                    rd_state <= HEADER;
                end
            end

            HEADER : begin
                mask_flag <= |(fifo_128_data_in [15:0]);
                rd_cnt <= fifo_128_data_in [23:16];

                if(!rah_out_prog_full && !fifo_128_empty) begin
                    fifo_128_rd_en <= 1;
                    rd_state <= HOLD;
                    data_flag <= 1;
                end
            end

            DATA : begin
                if(rd_cnt == 0) begin
                    if(wr_done_flag) begin
                        buf_cnt <= 0;
                        rd_state <= CHECK_EMPTY;
                    end
                end
                else begin
                    if(!rah_out_prog_full && !fifo_128_empty) begin
                        fifo_128_rd_en <= 1;
                        rd_state <= HOLD;
                    end
                end
            end
        endcase
    end
end

/* Logic to write into 48-bit fifo */
reg wr_state = 0;
localparam CHECK_COUNT = 0;
localparam WRITE_REM_DATA = 1;

always@(posedge clk) begin
    if(!rst_n) begin
        rah_fifo_wr_en <= 0;
        rah_fifo_wr_data <= 0;
        wr_cnt <= 0;
        wr_done_flag <= 0;
        wr_state <= CHECK_COUNT;
    end
    else begin
        case(wr_state)
            CHECK_COUNT : begin
                rah_fifo_wr_en <= 0;
                if((buf_cnt == wr_cnt) && (rd_cnt == 0)) begin
                    wr_cnt <= 0;
                    wr_done_flag <= 0;
                end
                else if(buf_cnt != wr_cnt) begin
                    rah_fifo_wr_en <= 1;
                    rah_fifo_wr_data <= fifo_128_data_in[111:64];
                    wr_state <= WRITE_REM_DATA;
                end
            end

            WRITE_REM_DATA : begin
                wr_cnt <= wr_cnt + 1;
                wr_state <= CHECK_COUNT;

                if((rd_cnt == 0) && (wr_cnt == (buf_cnt - 1))) begin
                    wr_done_flag <= 1;

                    if(!mask_flag) begin
                        rah_fifo_wr_en <= 1;
                        rah_fifo_wr_data <= fifo_128_data_in[47:0];
                    end
                    else begin
                        rah_fifo_wr_en <= 0;
                    end
                end
                else begin
                    rah_fifo_wr_en <= 1;
                    rah_fifo_wr_data <= fifo_128_data_in[47:0];
                end
            end
        endcase
    end
end

/* This is for debug purpose only */
reg [31:0]  read_count_rdside = 0;
reg [31:0] rah_wr_cnt = 0;

always@(posedge clk) begin
    if (!rst_n) begin
        read_count_rdside <= 0;
    end else begin
        if (fifo_128_rd_en) begin
            read_count_rdside <= read_count_rdside + 1;
        end else begin
            read_count_rdside <= read_count_rdside;
        end
    end
end

always@(posedge clk) begin
    if(rah_fifo_wr_en) begin
        rah_wr_cnt <= rah_wr_cnt + 1;
    end
end

endmodule
