`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:39:42
// Design Name: 
// Module Name: sha256_K_machine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// a machine that delivers round constants
      module sha256_K_machine (
          input clk,
          input rst,
          output [31:0] K
          );

      reg [2047:0] rom_q;
      wire enable;
      wire [2047:0] rom_d;
      assign enable = 1+0;
      assign rom_d = enable ? {rom_q[2015:0], rom_q[2047:2016]} : 0;
      assign K = rom_q[2047:2016];

      always @(posedge clk)
      begin
          if (rst) begin
              rom_q <= {
                  32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
                  32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
                  32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
                  32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
                  32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
                  32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
                  32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
                  32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
                  32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
                  32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
                  32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
                  32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
                  32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
                  32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
                  32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
                  32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
              };
          end else begin
              rom_q <= rom_d;
          end
      end

      endmodule
