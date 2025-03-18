module dout (
    input             clk,
    input      [39:0] int_1,
    input      [39:0] int_2,
    input      [39:0] int_3,
    input      [39:0] frec_1,
    input      [39:0] frec_2,
    input      [39:0] frec_3,
    input      [79:0] float_1,
    input      [79:0] float_2,
    input      [79:0] float_3,
    input      [ 2:0] app,
    input      [ 2:0] size,
    input             done_1,
    input             done_2,
    input             done_3,
    input             done_4,
    input             done_5,
    input             done_6,
    output reg [47:0] dataout = 48'b0,
    output reg        wren = 0
);

  integer count = 0;
  always @(posedge clk) begin
    if (app == 1) begin
      if (size == 1) begin
        if (done_1 == 1) begin
          wren = 1;
          dataout = {2'b01, 3'b001, 3'b000, int_1[15:0], frec_1[15:0], 8'b0};
        end else begin
          wren = 0;
          dataout = {2'b01, 3'b001, 3'b000, 39'b0};
        end
      end else if (size == 2) begin
        if (done_2 == 1) begin
          if (count == 2'b00) begin
            wren = 1;
            dataout = {2'b01, 3'b010, 3'b001, int_2[31:0], 8'b0};
            count = count + 1;
          end else if (count == 2'b01) begin
            wren = 1;
            dataout = {2'b01, 3'b010, 3'b010, frec_2[31:0], 8'b0};
            count = 0;
          end
        end else begin
          wren = 0;
          dataout = {2'b01, 3'b010, 3'b000, 39'b0};
        end
      end else if (size == 3) begin
        if (done_6 == 1) begin
          if (count == 2'b00) begin
            wren = 1;
            dataout = {2'b01, 3'b011, 3'b001, int_3};
            count = count + 1;
          end else if (count == 2'b01) begin
            wren = 1;
            dataout = {2'b01, 3'b011, 3'b010, frec_3};
            count = 0;
          end
        end else begin
          wren = 0;
          dataout = {2'b01, 3'b011, 3'b000, 39'b0};
        end

      end
    end else if (app == 2) begin
      if (size == 1) begin
        if (done_3 == 1) begin
          wren = 1;
          dataout = {2'b10, 3'b001, 3'b000, float_1[31:0], 8'b0};
        end else begin
          wren = 0;
          dataout = {2'b10, 3'b001, 3'b000, 39'b0};
        end
      end else if (size == 2) begin
        if (done_4 == 1) begin
          if (count == 2'b00) begin
            wren = 1;
            dataout = {2'b10, 3'b010, 3'b001, float_2[63:24]};
            count = count + 1;
          end else if (count == 2'b01) begin
            wren = 1;
            dataout = {2'b10, 3'b010, 3'b010, float_2[23:0], 16'b0};
            count = 0;
          end
        end else begin
          wren = 0;
          dataout = {2'b10, 3'b010, 3'b000, 39'b0};
        end
      end else if (size == 3) begin
        if (done_5 == 1) begin
          if (count == 2'b00) begin
            wren = 1;
            dataout = {2'b10, 3'b011, 3'b001, float_3[79:40]};
            count = count + 1;
          end else if (count == 2'b01) begin
            wren = 1;
            dataout = {2'b10, 3'b011, 3'b010, float_3[39:0]};
            count = 0;
          end
        end else begin
          wren = 0;
          dataout = {2'b11, 3'b011, 3'b000, 39'b0};
        end
      end
    end else begin
      wren = 0;
      dataout = 48'b0;
    end
  end
endmodule
