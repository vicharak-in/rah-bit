`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.01.2025 10:41:27
// Design Name: 
// Module Name: W_machine
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


// the message schedule: a machine that generates Wt values
      module W_machine #(parameter WORDSIZE=1) (
          input clk,
          input [WORDSIZE*16-1:0] M,
          input M_valid,
          output [WORDSIZE-1:0] W_tm2, W_tm15,
          input [WORDSIZE-1:0] s1_Wtm2, s0_Wtm15,
          output [WORDSIZE-1:0] W
          );
          
          
      reg [WORDSIZE*16-1:0] W_stack_q;

      // W(t-n) values, from the perspective of Wt_next
      assign W_tm2 = W_stack_q[WORDSIZE*2-1:WORDSIZE*1];
      assign W_tm15 = W_stack_q[WORDSIZE*15-1:WORDSIZE*14];
      wire [WORDSIZE-1:0] W_tm7 = W_stack_q[WORDSIZE*7-1:WORDSIZE*6];
      wire [WORDSIZE-1:0] W_tm16 = W_stack_q[WORDSIZE*16-1:WORDSIZE*15];
      // Wt_next is the next Wt to be pushed to the queue, will be consumed in 16 rounds
      wire [WORDSIZE-1:0] Wt_next = s1_Wtm2 + W_tm7 + s0_Wtm15 + W_tm16;

      
      wire [WORDSIZE*16-1:0] W_stack_d = {W_stack_q[WORDSIZE*15-1:0], Wt_next};
      assign W = W_stack_q[WORDSIZE*16-1:WORDSIZE*15];

      always @(posedge clk)
      begin
          if (M_valid) begin
              W_stack_q <= M;
          end else begin
              W_stack_q <= W_stack_d;
          end
      end

      endmodule