module calc(
    input         clk,
    input         rstn,
    input [47:0]  datain,
    input         empty,
    output [47:0] dataout,
    output reg    rden,
    output        wren
);

wire [79:0]  a;
wire [79:0]  b;
wire [2:0]   app;
wire         sel;
wire         en;
wire         done;
wire [159:0] c;

always @(posedge clk) begin
    if (empty == 0) rden = 1;
    else if (empty == 1) rden = 0;
end

collector uc(
    .clk    (clk),
    .rstn   (rstn),
    .datain (datain),
    .a      (a),
    .b      (b),
    .app    (app),
    .sel    (sel),
    .en     (en)
);

alu ua(
    .clk   (clk),
    .rstn  (rstn),
    .en    (en),
    .app   (app),
    .sel   (sel),
    .a     (a),
    .b     (b),
    .c     (c),
    .done  (done)
);

dout du(
    .clk     (clk),
    .c       (c),
    .app     (app),
    .sel     (sel),
    .done    (done),
    .dataout (dataout),
    .wren    (wren)
);
endmodule