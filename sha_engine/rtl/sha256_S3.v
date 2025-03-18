module sha256_S3 (
          input wire [31:0] x,
          output wire [31:0] S3
          );

      assign S3 = ({x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]});

      endmodule