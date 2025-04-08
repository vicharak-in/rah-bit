module collector (
    input                      clk,
    input                      rstn,
    input [DATAIN-1:0]         datain,
    output reg [INT_WID-1:0]   int = 0,
    output reg [FREC_WID-1:0]  frec = 0,
    output reg [FLOAT_WID-1:0] float = 0,
    output reg [APP-1:0]       app = 0,
    output reg [SIZE-1:0]      size = 0,
    output reg                 clk_en_1 = 0,
    output reg                 clk_en_2 = 0,
    output reg                 clk_en_3 = 0,
    output reg                 clk_en_4 = 0,
    output reg                 clk_en_5 = 0,
    output reg                 clk_en_6 = 0
);
    
parameter INT_WID = 40;
parameter FREC_WID = 40;
parameter FLOAT_WID = 80;
parameter DATAIN = 48;
parameter APP = 2;
parameter SIZE = 3;

reg [2:0] packet = 0;
reg [39:0] data = 0;

always @(posedge clk) begin
    app <= datain[47:46];
    size <= datain[45:43];
    packet <= datain[42:40];
    data <= datain[39:0];
    
    if (app == 2'b01) begin
        if (size == 3'b001 && packet == 3'b000) begin
            float <= data[39:8];
            clk_en_1 <= 1'b1;
            clk_en_2 <= 1'b0;
            clk_en_3 <= 1'b0;
            clk_en_4 <= 1'b0;
            clk_en_5 <= 1'b0;
            clk_en_6 <= 1'b0;
        end else if (size == 3'b010) begin
            if (packet == 3'b001) begin
                float[79:40] <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b1;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b0;
            end else if (packet == 3'b010) begin
                float[39:0] <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b1;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b0;
            end
        end else if (size == 3'b011) begin
            if (packet == 3'b001) begin
                float[79:40] <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b1;
            end else if (packet == 3'b010) begin
                float[39:0] <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b1;
            end
        end else begin
            clk_en_1 <= 1'b0;
            clk_en_2 <= 1'b0;
            clk_en_6 <= 1'b0;
        end
    end else if (app == 2'b10) begin
        if (size == 3'b001 && packet == 3'b000) begin
            int <= data[39:24];
            frec <= data[23:8];
            clk_en_1 <= 1'b0;
            clk_en_2 <= 1'b0;
            clk_en_3 <= 1'b1;
            clk_en_4 <= 1'b0;
            clk_en_5 <= 1'b0;
            clk_en_6 <= 1'b0;
        end else if (size == 3'b010) begin
            if (packet == 3'b001) begin
                int <= data[39:8];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b1;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b0;
            end else if (packet == 3'b010) begin
                frec <= data[39:8];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b1;
                clk_en_5 <= 1'b0;
                clk_en_6 <= 1'b0;
            end
        end else if (size == 3'b011) begin
            if (packet == 3'b001) begin
                int <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b1;
                clk_en_6 <= 1'b0;
            end else if (packet == 3'b010) begin
                frec <= data[39:0];
                clk_en_1 <= 1'b0;
                clk_en_2 <= 1'b0;
                clk_en_3 <= 1'b0;
                clk_en_4 <= 1'b0;
                clk_en_5 <= 1'b1;
                clk_en_6 <= 1'b0;
            end
        end else begin
            clk_en_3 <= 1'b0;
            clk_en_4 <= 1'b0;
            clk_en_5 <= 1'b0;
        end
    end else begin
        clk_en_3 <= 1'b0;
        clk_en_4 <= 1'b0;
        clk_en_1 <= 1'b0;
        clk_en_2 <= 1'b0;
        clk_en_5 <= 1'b0;
        clk_en_6 <= 1'b0;
    end
end    
endmodule