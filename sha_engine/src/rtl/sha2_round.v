`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:47:17
// Design Name: 
// Module Name: sha2_round
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


// generalised round compression function
      module sha2_round #(
          parameter WORDSIZE=0
      ) (
          input [WORDSIZE-1:0] Kj, Wj,
          input [WORDSIZE-1:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
          input [WORDSIZE-1:0] Ch_e_f_g, Maj_a_b_c, S4_a, S3_e,
          output [WORDSIZE-1:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out
          );

      wire [WORDSIZE-1:0] T1 = h_in + S3_e + Ch_e_f_g + Kj + Wj;
      wire [WORDSIZE-1:0] T2 = S4_a + Maj_a_b_c;

      assign a_out = T1 + T2;
      assign b_out = a_in;
      assign c_out = b_in;
      assign d_out = c_in;
      assign e_out = d_in + T1;
      assign f_out = e_in;
      assign g_out = f_in;
      assign h_out = g_in;

      endmodule
