module mem_rd_ctrl #(
    AXI_DATA_WIDTH = 128
)(
    input                              clk,
    input                              rst,
    input                              select_rd,
    input                              rvalid_rd,
    input                              rlast_rd,
    input [AXI_DATA_WIDTH - 1 :0]      rdata_in,
    output reg [AXI_DATA_WIDTH - 1 :0] rdata_out = 0,
    output reg                         data_valid = 0
);

reg [AXI_DATA_WIDTH - 1 : 0] delay_rd = 0;
reg [31:0] read_dram_count = 0;

always @ (posedge clk) begin
    if (!rst) begin
        rdata_out <= 0;
        data_valid <=  0;
    end else begin
        if ((select_rd == 1) && rvalid_rd) begin
            rdata_out <= delay_rd;
            data_valid <=  1'b1;
        end else begin
            rdata_out <= rdata_out;
            data_valid <=  0;
        end
    end
end

always  @ (posedge clk) begin
     delay_rd <= rdata_in;
end

always@(posedge clk) begin
    if (!rst) begin
        read_dram_count <= 0;
    end else begin
        if (data_valid) begin
            read_dram_count <= read_dram_count + 1;
        end
        else begin
            read_dram_count <= read_dram_count;
        end
    end
end

endmodule