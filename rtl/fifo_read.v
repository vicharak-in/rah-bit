module fifo (
    input                           clk,
    input                           rst,
    input                           write,
    input                           read,
    input [width-1:0]               buf_in,
    output reg [width-1:0]          buf_out = 0,
    output                          buf_em,
    output                          buf_almost_em,
    output                          buf_full,
    output reg [counter_width-1:0]  buf_count = 0,
    output                          pr_full
);

parameter width = 256;
parameter depth = 512; // Maximum depth of the FIFO buffer
parameter counter_width = $clog2(depth); // Width of the counter

reg [counter_width:0] rd_ptr, wr_ptr;
reg [width-1:0] memory [depth-1:0];

assign buf_em = (buf_count == 0);
assign buf_almost_em = (buf_count <= 1);
assign buf_full = (buf_count == depth - 1);
assign pr_full = (buf_count == depth - 12);    

always @(posedge clk) if (read) buf_out <= memory[rd_ptr];  
always @(posedge clk) if (write) memory[wr_ptr] <= buf_in;

always @(posedge clk) begin    
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        buf_count <= 0;
    end else begin
        if (write) wr_ptr <= (wr_ptr == depth - 1) ? 0 : wr_ptr + 1;  
        if (read) rd_ptr <= (rd_ptr == depth - 1) ? 0 : rd_ptr + 1;

        case ({write & ~buf_full, read & ~buf_em})
            2'b10: buf_count <= buf_count + 1;
            2'b01: buf_count <= buf_count - 1;
            default: buf_count <= buf_count;
        endcase

    end  
end

endmodule
