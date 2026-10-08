module mem_wr_ctrl (
    input                   clk,
    input                   rst,
    input                   select,
    input [31:0]            in_addr,
    input [7:0]             BLEN_w,
    input                   wready_w,
    input                   read_done,
    output reg              w_valid,
    output reg              w_last,
    output reg              WriteEn, // FIFO read enable
    output reg              header,
    output reg [31:0]       write_counter
);

/* Internal register Declarations */
reg [ 7:0] count_blen = 0;
reg [31:0] addr = 0;
reg [31:0] read_fifo_count = 0;
reg [31:0] write_valid_count = 0;
reg [31:0] wready_wvalid_count = 0;

/* FSM State parameter Declaration */
reg [ 1:0] state = 0;
parameter CHECK_FOR_SELECT  = 2'b00;
parameter WRITE_HEADER_DATA = 2'b01;
parameter DELAY_SELECT      = 2'b10;
parameter CHECK_BLEN_COUNT  = 2'b11;

// FSM for memory write control
always@(posedge clk) begin
    if(!rst) begin // Reset condition
        w_valid <= 0;
        count_blen <= 0;
        addr <= 0;
        WriteEn <= 0;
        w_last <= 0;
        header <= 0;
        state <= CHECK_FOR_SELECT;
    end else begin
        case (state)
            CHECK_FOR_SELECT : begin
                // Check if a write operation is selected
                if (select) begin
                    w_valid  <= 0;
                    count_blen <= 0;
                    addr <= in_addr;
                    WriteEn <= 0;
                    w_last <= 0;
                    state  <= WRITE_HEADER_DATA;
                end else begin
                    w_valid  <= 0;
                    count_blen <= 0;
                    addr <= addr;
                    WriteEn <= 0;
                    w_last <= 0;
                    state  <= CHECK_FOR_SELECT;
                end
            end

            WRITE_HEADER_DATA : begin
                if (select && wready_w) begin
                    header <= 1;
                    w_valid <= 1;
                    w_last <= 0;
                    WriteEn <= 1;
                    count_blen <= count_blen + 1;
                    addr <= addr + 16;
                    state <= CHECK_BLEN_COUNT;
                end
            end

            DELAY_SELECT : begin
                header <= 0;
                // Delay before starting the write operation
                if (count_blen > (BLEN_w)) begin
                    w_valid <= 0;
                    w_last <= 0;
                    WriteEn <= 0;
                    count_blen <= 0;
                    state  <= CHECK_FOR_SELECT;
                end else if(select && wready_w) begin
                    WriteEn <= 1;
                    w_valid <= 0;
                    w_last  <= 0;
                    state   <= CHECK_BLEN_COUNT;
                end else begin
                    w_valid <= 0;
                    state <= DELAY_SELECT;
                end
            end

            CHECK_BLEN_COUNT : begin
                WriteEn <= 0;
                header <= 0;
                if (count_blen == (BLEN_w)) begin
                    // If the burst length counter matches the input BLEN_w
                    if (wready_w == 1) begin
                        w_valid <= 1;
                        w_last <= 1;
                        addr <= addr + 16;
                        count_blen <= count_blen + 1;
                        state <= DELAY_SELECT;
                    end else begin
                        w_valid <= w_valid;
                        count_blen <= count_blen;
                        addr <= addr;
                        state <= CHECK_BLEN_COUNT;
                    end
                end else begin
                    if (wready_w == 1)  begin
                        w_valid  <= 1;
                        w_last <= 0;
                        addr  <= addr + 16;
                        count_blen <= count_blen + 1;
                        state  <= DELAY_SELECT;
                    end else begin
                        addr <= addr;
                        w_valid <= w_valid;
                        state  <= CHECK_BLEN_COUNT;
                    end
                end
            end
        endcase
     end
end

/* To monitor the write and read requests granted */
always@(posedge clk) begin
    if (!rst) begin
        write_counter <= 0;
    end else begin
        if (w_last && read_done) begin
            write_counter <= write_counter;
        end else if (w_last) begin
            write_counter <= write_counter + 1;
        end else if (read_done) begin
            write_counter <= write_counter - 1;
        end else begin
            write_counter <= write_counter;
        end
    end
end

////////////////////////////////////////////////////////////////////////////////
/* This is for Debugging only */
reg [31:0] wlast_count = 0;
always@(posedge clk) begin
    if(!rst) begin
        wlast_count <= 0;
    end else begin
        if (w_last) begin
            wlast_count <= wlast_count + 1;
        end else begin
            wlast_count <= wlast_count;
        end
    end
end

always@(posedge clk) begin
    if (!rst) begin
        read_fifo_count <= 0;
    end
    else begin
        if (WriteEn) begin
            read_fifo_count <= read_fifo_count + 1;
        end else begin
            read_fifo_count <= read_fifo_count;
        end
    end
end

always@(posedge clk) begin
    if (!rst) begin
        write_valid_count <= 0;
    end
    else begin
        if (w_valid) begin
            write_valid_count <= write_valid_count + 1;
        end
        else begin
            write_valid_count <= write_valid_count;
        end
    end
end

always@(posedge clk) begin
    if (!rst) begin
        wready_wvalid_count <= 0;
    end
    else begin
        if (wready_w && w_valid) begin
            wready_wvalid_count <= wready_wvalid_count + 1;
        end
        else begin
            wready_wvalid_count <= wready_wvalid_count;
        end
    end
end

endmodule