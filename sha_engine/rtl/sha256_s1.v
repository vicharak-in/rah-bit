module sha256_s1 (
          input wire [31:0] x,
          output wire [31:0] s1
          );

      assign s1 = ({x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10));

      endmodule