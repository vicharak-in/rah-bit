module wr_req_ctrl #(
    parameter THRESHOLD_VALUE   = 128,
    parameter WAIT_CYCLE_COUNT  = 5,
    parameter AXI_BYTES         = 16,
    parameter INPUT_DATA_WIDTH  = 48,
    parameter OUTPUT_DATA_WIDTH = 128,
    parameter FIFO_OCC_WIDTH    = 9
) (
    /* System Clock Signal */
    input                                   clk,

    /* System Reset Signal */
    input                                   rst,

    /* Start and Stop Adresses of DRAM */
    input [31:0]                            start_addr,
    input [31:0]                            stop_addr,

    /* Write request signals to Port controller */
    output reg                              valid,
    output reg                              last,
    output reg                              rw_enable,
    output reg [ 7:0]                       addr,
    output reg [ 7:0]                       burst_length,

    /* Rah Fifo interface Signals */
    input                                   rah_fifo_a_empty,
    input                                   rah_fifo_empty,
    input [INPUT_DATA_WIDTH - 1 :0]         rah_fifo_data_in,
    output reg                              rah_fifo_rd_en,

    /* 128-bit fifo that store data which read from rah fifo */
    input[FIFO_OCC_WIDTH - 1 : 0]           fifo_occupants,
    input                                   fifo_128_full,
    input                                   fifo_128_prog_full,
    output reg                              fifo_128_wr_en,
    output reg [OUTPUT_DATA_WIDTH - 1 :0]   fifo_128_data_out,

    /* Wlast and header data signals to Wr_Mem_ctrl */
    input                                   data_last,
    output reg [OUTPUT_DATA_WIDTH - 1 :0]   header_data
);

/* Internal Register Declaration */
reg [31:0] current_addr = 0;
reg [31:0] nxt_addr = 0;
reg [ 7:0] r_blen = 0;
reg [10:0] prev_fifo_occ = 0;
reg [ 3:0] wait_count = 0;
reg [ 2:0] count_addr = 0;
reg [31:0] Total_locations_need = 0; 
reg [31:0] Extra_locations_need = 0; 
wire[31:0] remaining_locations;
wire[31:0] space_left;
reg        odd = 0;
reg        mask = 0;

/* FSM state parameters Declaration */
reg [3:0] state = 0;
parameter START_CONDITION         = 4'h0;
parameter CHECK_FIFO_OCCUPANTS    = 4'h1;
parameter WAIT_FOR_THRESHOLD_CNT  = 4'h2;
parameter CHECK_PADD_DONE         = 4'h3;
parameter UPDATE_NXT_ADDR         = 4'h4;
parameter COMPARE_NXT_ADDR        = 4'h5;
parameter GENERATE_WR_REQUEST     = 4'h6;
parameter WAIT_FOR_DATA_LAST      = 4'h7;
parameter CHANGE_BLEN_CONDITION   = 4'h8;
parameter CONTINUE_REMAINING_BLEN = 4'h9;
parameter LOAD_HEADER_DATA        = 4'hA;
parameter UPDATE_BLEN_VALUE       = 4'hB;

/* Number of location remains in Dram Space */
assign remaining_locations  = Total_locations_need - Extra_locations_need;
assign space_left = (stop_addr - nxt_addr) >> 4;

/* Logic to generate Write requests based on data availability */
always@(posedge clk) begin
    if(!rst) begin
        valid <= 0;
        last <= 0;
        rw_enable <= 0;
        addr <= 0;
        burst_length <= 0;
        current_addr <= 0;
        nxt_addr <= 0;
        r_blen <= 0;
        state <= 0;
        prev_fifo_occ <= 0;
        wait_count <= 0;
        mask <= 0;
        header_data <= 0;
    end else begin
        case(state)
            START_CONDITION : begin
                if(start_addr < stop_addr) begin
                    nxt_addr <= start_addr;
                    state <= CHECK_FIFO_OCCUPANTS;
                end
            end

            CHECK_FIFO_OCCUPANTS : begin
                if(space_left <= 32'd2) begin
                    nxt_addr <= start_addr;
                end else begin
                    if((rah_fifo_rd_en) && (fifo_occupants == 0)) begin
                        prev_fifo_occ  <= fifo_occupants;
                        state <= WAIT_FOR_THRESHOLD_CNT;
                    end else if(fifo_occupants == 0) begin
                        state <= CHECK_FIFO_OCCUPANTS;
                    end else if(fifo_occupants >= THRESHOLD_VALUE) begin
                        r_blen <= THRESHOLD_VALUE;
                        burst_length <= THRESHOLD_VALUE;
                        current_addr <= nxt_addr;
                        state  <= UPDATE_NXT_ADDR;
                    end else begin
                        prev_fifo_occ  <= fifo_occupants;
                        state  <= WAIT_FOR_THRESHOLD_CNT;
                    end
                end
            end

            WAIT_FOR_THRESHOLD_CNT : begin
                if(prev_fifo_occ == fifo_occupants) begin
                    if (wait_count == WAIT_CYCLE_COUNT) begin
                        wait_count <= 0;

                        if(rah_fifo_empty && phase) begin
                            padd <= 1;
                            state <= CHECK_PADD_DONE;
                        end else begin
                            r_blen <= fifo_occupants;
                            burst_length <= fifo_occupants;
                            current_addr <= nxt_addr;
                            mask <= 0;
                            state <= UPDATE_NXT_ADDR;
                        end
                    end else begin
                        wait_count <= wait_count + 1;
                        state <= WAIT_FOR_THRESHOLD_CNT;
                    end
                end else begin
                    wait_count <= 0 ;
                    state <= CHECK_FIFO_OCCUPANTS ;
                end
            end

            CHECK_PADD_DONE : begin
                padd <= 0;

                if (padd_done) begin
                    state <= UPDATE_BLEN_VALUE;
                end
            end

            UPDATE_BLEN_VALUE : begin
                r_blen <= fifo_occupants;
                burst_length <= fifo_occupants;
                current_addr <= nxt_addr;
                mask <= 1;
                state <= UPDATE_NXT_ADDR;
            end

            UPDATE_NXT_ADDR : begin
                nxt_addr <= (current_addr + ((burst_length + 1)
                                << $clog2(AXI_BYTES)));
                state <= COMPARE_NXT_ADDR;
            end

            COMPARE_NXT_ADDR : begin
                if(nxt_addr <= stop_addr) begin
                    state <= LOAD_HEADER_DATA;
                end else begin
                    Total_locations_need <= (nxt_addr - current_addr) >> 4;
                    Extra_locations_need <= (nxt_addr - stop_addr) >> 4;
                    state <= CHANGE_BLEN_CONDITION;
                end
            end

            CHANGE_BLEN_CONDITION : begin
                burst_length <= remaining_locations - 1 ;
                current_addr <= current_addr;
                odd <= 1;
                state <= UPDATE_NXT_ADDR;
            end

            LOAD_HEADER_DATA :  begin
                if (mask && !odd) begin
                    header_data <= {104'b0, burst_length, 16'hFFFF};
                    mask <= 0;
                    state <= GENERATE_WR_REQUEST;
                end else begin
                    header_data <= {104'b0, burst_length, 16'b0};
                    state <= GENERATE_WR_REQUEST;
                end
            end

            GENERATE_WR_REQUEST: begin
                addr <= current_addr[32 - (count_addr * 8) - 1 -: 8];
                rw_enable <= 1;
                valid <= 1;
                burst_length <= burst_length;

                if(count_addr < 3) begin
                    count_addr <= count_addr + 1;
                    last <= 0;
                end
                else begin
                    count_addr <= 0;
                    last <= 1;

                    if ((burst_length < r_blen) && odd) begin
                        state <= CONTINUE_REMAINING_BLEN;
                    end else begin
                        state <= WAIT_FOR_DATA_LAST;
                    end
                end
            end

            WAIT_FOR_DATA_LAST: begin
                last <= 0;
                valid <= 0;
                addr <= 0;
                rw_enable <= 1;
                burst_length <= burst_length;

                if(data_last) begin
                    if(nxt_addr == stop_addr) begin
                        state <= START_CONDITION;
                    end else begin
                        state <= CHECK_FIFO_OCCUPANTS;
                    end
                end
            end

            CONTINUE_REMAINING_BLEN : begin
                last <= 0;
                valid <= 0;
                addr <= 0;
                rw_enable <= 1;
                burst_length <= burst_length;
                odd <= 0;

                if(data_last) begin
                    current_addr <= start_addr;
                    burst_length <= Extra_locations_need;
                    state <= UPDATE_NXT_ADDR;
                end
            end
        endcase
   end
end

/* Logic to read from 48-bit fifo and write into 128-bit fifo */
reg padd  = 0;
reg padd_done = 0;
reg [31:0] rah_rd_cnt = 0;
reg phase = 0;
reg rah_rd_delay = 0;
reg rah_empty_delay = 0;

always@(posedge clk) begin
    if(!rst) begin
        rah_fifo_rd_en <= 0;
        rah_rd_cnt <= 0;
    end
    else begin
        if (fifo_128_prog_full || (rah_fifo_rd_en && rah_fifo_a_empty)) rah_fifo_rd_en <= 0;
        else if (~rah_fifo_empty) begin
            rah_fifo_rd_en <= 1;
            rah_rd_cnt <= rah_rd_cnt + 1;
        end
    end
end

always@(posedge clk) begin
      if(!rst) begin
          fifo_128_wr_en <= 0;
          fifo_128_data_out <= 0;
          phase <= 0;
          padd_done <= 0;
      end
      else begin
          fifo_128_wr_en <= 0;
          padd_done <= 0;
          rah_rd_delay <= rah_fifo_rd_en;
          rah_empty_delay <= rah_fifo_empty;

          if(rah_rd_delay) begin
              if(!phase) begin
                 fifo_128_data_out [127:64] <= {16'b0, rah_fifo_data_in};
                 phase <= 1;
              end
              else begin
                 fifo_128_data_out [63:0] <= {16'b0, rah_fifo_data_in};
                 fifo_128_wr_en <= 1;
                 phase <= 0;
              end
          end
          else if(rah_empty_delay && padd && phase) begin
              fifo_128_data_out <= {fifo_128_data_out[127:64], 64'b0};
              padd_done <= 1;
              phase <= 0;
              fifo_128_wr_en  <= 1;
          end
      end
end

/* This is for debug purpose only */
reg [31:0] write_fifo_count = 0;

always@(posedge clk) begin
    if (!rst) begin
        write_fifo_count <= 0;
    end else begin
        if (fifo_128_wr_en) begin
            write_fifo_count <= write_fifo_count + 1;
        end else begin
            write_fifo_count <= write_fifo_count;
        end
    end
end

endmodule
