`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:44:11
// Design Name: 
// Module Name: Ch
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


// Ch(x,y,z)
      module Ch #(parameter WORDSIZE=0) (
          input wire [WORDSIZE-1:0] x, y, z,
          output wire [WORDSIZE-1:0] Ch
          );

      assign Ch = ((x & y) ^ (~x & z));

      endmodule