module tran_cont (
    input               clk,
    input               empty,
    input               almost_empty,
    input [47:0]        data,
    input               wr_full,
    output reg          RD_en = 0,
    output reg          wr_en = 0,
    output reg [47:0]   wr_data = 0
);

reg [3:0] count = 8;
reg [3:0] count1 = 0;
reg [1:0]state = 0;
reg [255:0] rdata = 0;
reg [255:0] wr_st = 0;
reg [255:0] wr_ff_st = 0;
reg [255:0] out_data = 0;
reg start = 0;
reg valid = 0;
reg reset = 0;
reg read = 0;
reg st_rd = 0;
reg get_valid = 0;
reg rd_state, rd_state_f;

wire done;
wire pr_full;
wire pr_full_out;
wire buff_full_out;
wire buf_full;
wire buf_em;
wire buf_almost_em;
wire buf_em_out;
wire buf_almost_em_out;
wire [31:0] dct_out0;
wire [31:0] dct_out1;
wire [31:0] dct_out2;
wire [31:0] dct_out3;
wire [31:0] dct_out4;
wire [31:0] dct_out5;
wire [31:0] dct_out6;
wire [31:0] dct_out7;
wire [255:0] wr_st_in;
wire [255:0] wr_st_out;

// ==== READ LOGIC ====
always @(posedge clk) begin
    rd_state <= RD_en;
    RD_en <= ~almost_empty | (~RD_en & ~empty);

    if (rd_state) begin
        rdata[(count * 32) - 1 -: 32] <= data[31:0];

        if (count == 1) begin
            count <= 8;
            rd_state_f <= 1;
        end else begin
            count <= count - 1;
            rd_state_f <= 0;
        end
    end else begin
        rd_state_f <= 0;
    end
end


// ==== FIFO WRITE ====
always @(posedge clk) begin
    if (rd_state_f) begin
        out_data <= rdata;
        start <= 1;
    end else begin
        start <= 0;
        out_data <= 0;
    end
end 

// ==== DCT WRITE ====
always @(posedge clk) begin
    read <= ~buf_almost_em | (~read & ~buf_em);
    // st_rd <= ~buf_em & read;
    st_rd <= read;
end

always @(posedge clk) begin
    if (st_rd) begin
        //reset <= 0;
        wr_st <= wr_st_in;
        valid <= 1;
    end else begin
        valid <= 0;
        wr_st <= 0;
    end
end

// ==== DCT READ/FIFO READ/READ LOGIC ====
always @(posedge clk) begin
    case (state)
        0: begin 
            if (~buf_em_out) begin
                get_valid <= 1;
                state <= 1;
            end else begin
                get_valid <= 0;
            end
        end 

        1: begin 
            state <= 2;
            get_valid <= 0;
        end

        2: begin
            wr_ff_st <= wr_st_out;
            state <= 3;
        end

        3: begin
            if (count1 < 8) begin
                wr_data <= {16'b0, wr_ff_st[(count1 * 32) +: 32]};

                if (~wr_full) begin
                    wr_en <= 1;
                    count1 <= count1 + 1;
                end else begin
                    wr_en <= 0;
                end
            end else if (count1 == 8) begin
                wr_ff_st <= 0;
                count1 <= 0;
                wr_data <= 0;
                wr_en <= 0;
                state <= 0;
            end 
        end 
    endcase
end

wire [255:0] f2_wdata;
assign f2_wdata = {
    dct_out7, dct_out6, dct_out5, dct_out4,
    dct_out3, dct_out2, dct_out1, dct_out0
};
// ==== FIFO INSTANTIATION ====

`undef DEBUG
`ifdef DEBUG

// FIFO for DCT input
sync_fifo_ip f1 ( 
    .a_rst_i        (reset),
    .clk_i          (clk),
    .wr_en_i        (start),
    .wdata          (out_data),
    .rdata          (wr_st_in),
    .rd_en_i        (read),
    .empty_o        (buf_em),
    .prog_full_o    (pr_full),
    .almost_empty_o (buf_almost_em)
);

// FIFO for DCT output
sync_fifo_ip f2 (
    .a_rst_i        (reset),
    .clk_i          (clk),
    .wr_en_i        (done),
    .wdata          (f2_wdata),
    .rdata          (wr_st_out),
    .rd_en_i        (get_valid),
    .empty_o        (buf_em_out),
    .prog_full_o    (pr_full_out),
    .almost_empty_o (buf_almost_em_out)
);

`else
// FIFO for DCT input
fifo f11 ( 
    .buf_in (out_data),
    .clk (clk),
    .write (start),
    .buf_out (wr_st_in),
    .read (read),
    .buf_em (buf_em),
    .buf_almost_em (buf_almost_em),
    .rst (reset),
    .buf_full (buf_full),
    .pr_full (pr_full)
);

// FIFO for DCT output
fifo f21 (
    .buf_in (f2_wdata),
    .clk (clk),
    .write (done),
    .buf_out (wr_st_out),
    .buf_em (buf_em_out),
    .buf_almost_em (buf_almost_em_out),
    .read (get_valid),
    .rst (reset),
    .buf_full (buff_full_out),
    .pr_full (pr_full_out)
);

`endif
  
// ==== DCT INSTANTIATION ====
dct_core dct_co(
    .clk (clk),
    .rst_n (reset),
    .start (valid),
    .a1 (wr_st),
    .done (done),
    .g0 (dct_out0),
    .g1 (dct_out1),
    .g2 (dct_out2),
    .g3 (dct_out3),
    .g4 (dct_out4),
    .g5 (dct_out5),
    .g6 (dct_out6),
    .g7 (dct_out7)
);

endmodule  
