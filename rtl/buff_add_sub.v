module buff (
input clk,
input rst,
input enable, 
input [31:0] in_data,
output reg [31:0] out_data
);

reg [31:0] bsa;
reg [31:0] bsn;
reg [31:0]  bus;
reg [31:0] bsz;
reg [31:0]  buz;

always @(posedge clk) begin
    if (enable) begin 
    bsa <= in_data;
    end else begin 
    bsa <= 0;
    end 
 end
always @(posedge clk) begin    
    bsn <= bsa;
    bus <= bsn;
    bsz <= bus;
    buz <= bsz;
    out_data <= buz;
end 
  endmodule   
