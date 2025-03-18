module Ch #(parameter WORDSIZE=0) (
          input wire [WORDSIZE-1:0] x, y, z,
          output wire [WORDSIZE-1:0] Ch
          );

      assign Ch = ((x & y) ^ (~x & z));

      endmodule