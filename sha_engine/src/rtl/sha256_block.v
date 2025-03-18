`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:51:22
// Design Name: 
// Module Name: sha256_block
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


// block processor
      // NB: master *must* continue to assert H_in until we have signaled output_valid
      module sha256_block (
          input clk, rst,
          input [255:0] H_in,
          input [511:0] M_in,
          input input_valid,
          output [255:0] H_out,
          output output_valid
          );

      reg [6:0] round;
      wire [31:0] a_in = H_in[255:224], b_in = H_in[223:192], c_in = H_in[191:160], d_in = H_in[159:128];
      wire [31:0] e_in = H_in[127:96], f_in = H_in[95:64], g_in = H_in[63:32], h_in = H_in[31:0];
      reg [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;
      wire [31:0] a_d, b_d, c_d, d_d, e_d, f_d, g_d, h_d;
      wire [31:0] W_tm2, W_tm15, s1_Wtm2, s0_Wtm15, Wj, Kj;
      // Only update H_out when output_valid is asserted
      assign H_out = (output_valid) ? {
      a_in + a_q, b_in + b_q, c_in + c_q, d_in + d_q,
      e_in + e_q, f_in + f_q, g_in + g_q, h_in + h_q
      } : H_out;
      assign output_valid = round == 64;

      always @(posedge clk or posedge rst)
begin
    if (rst) begin
        // Reset all registers to their initial state
        a_q <= 32'b0; b_q <= 32'b0; c_q <= 32'b0; d_q <= 32'b0;
        e_q <= 32'b0; f_q <= 32'b0; g_q <= 32'b0; h_q <= 32'b0;
        round <= 7'b0;
    end else if (input_valid) begin
        a_q <= a_in; b_q <= b_in; c_q <= c_in; d_q <= d_in;
        e_q <= e_in; f_q <= f_in; g_q <= g_in; h_q <= h_in;
        round <= 0;
    end else begin
        a_q <= a_d; b_q <= b_d; c_q <= c_d; d_q <= d_d;
        e_q <= e_d; f_q <= f_d; g_q <= g_d; h_q <= h_d;
        round <= round + 1;
    end
end


      sha256_round sha256_round (
          .Kj(Kj), .Wj(Wj),
          .a_in(a_q), .b_in(b_q), .c_in(c_q), .d_in(d_q),
          .e_in(e_q), .f_in(f_q), .g_in(g_q), .h_in(h_q),
          .a_out(a_d), .b_out(b_d), .c_out(c_d), .d_out(d_d),
          .e_out(e_d), .f_out(f_d), .g_out(g_d), .h_out(h_d)
      );

      sha256_s0 sha256_s0 (.x(W_tm15), .s0(s0_Wtm15));
      sha256_s1 sha256_s1 (.x(W_tm2), .s1(s1_Wtm2));

      W_machine #(.WORDSIZE(32)) W_machine (
          .clk(clk),
          .M(M_in), .M_valid(input_valid),
          .W_tm2(W_tm2), .W_tm15(W_tm15),
          .s1_Wtm2(s1_Wtm2), .s0_Wtm15(s0_Wtm15),
          .W(Wj)
      );

      sha256_K_machine sha256_K_machine (
          .clk(clk), .rst(input_valid), .K(Kj)
      );

      endmodule
