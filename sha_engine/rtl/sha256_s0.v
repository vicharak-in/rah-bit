module sha256_s0 (
          input wire [31:0] x,
          output wire [31:0] s0
          );

      assign s0 = ({x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3));

      endmodule