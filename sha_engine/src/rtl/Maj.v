`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:45:47
// Design Name: 
// Module Name: Maj
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


// Maj(x,y,z)
      module Maj #(parameter WORDSIZE=0) (
          input wire [WORDSIZE-1:0] x, y, z,
          output wire [WORDSIZE-1:0] Maj
          );

      assign Maj = (x & y) ^ (x & z) ^ (y & z);

      endmodule