module Maj #(parameter WORDSIZE=0) (
          input wire [WORDSIZE-1:0] x, y, z,
          output wire [WORDSIZE-1:0] Maj
          );

      assign Maj = (x & y) ^ (x & z) ^ (y & z);

      endmodule