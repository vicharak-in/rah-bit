`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:48:00
// Design Name: 
// Module Name: sha256_round
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


// round compression function
      module sha256_round (
          input [31:0] Kj, Wj,
          input [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
          output [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out
          );

      wire [31:0] Ch_e_f_g, Maj_a_b_c, S4_a, S3_e;

      Ch #(.WORDSIZE(32)) Ch (
          .x(e_in), .y(f_in), .z(g_in), .Ch(Ch_e_f_g)
      );

      Maj #(.WORDSIZE(32)) Maj (
          .x(a_in), .y(b_in), .z(c_in), .Maj(Maj_a_b_c)
      );

      sha256_S4 S4 (
          .x(a_in), .S4(S4_a)
      );

      sha256_S3 S3 (
          .x(e_in), .S3(S3_e)
      );

      sha2_round #(.WORDSIZE(32)) sha256_round_inner (
          .Kj(Kj), .Wj(Wj),
          .a_in(a_in), .b_in(b_in), .c_in(c_in), .d_in(d_in),
          .e_in(e_in), .f_in(f_in), .g_in(g_in), .h_in(h_in),
          .Ch_e_f_g(Ch_e_f_g), .Maj_a_b_c(Maj_a_b_c), .S4_a(S4_a), .S3_e(S3_e),
          .a_out(a_out), .b_out(b_out), .c_out(c_out), .d_out(d_out),
          .e_out(e_out), .f_out(f_out), .g_out(g_out), .h_out(h_out)
      );

      endmodule
