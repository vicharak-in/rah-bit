module sha256_block (
    input clk, rst,
    input [255:0] H_in,
    input [511:0] M_in,
    input input_valid,
    output reg [255:0] H_out,
    output reg output_valid
);

    reg [6:0] round;
    reg input_latched;

    wire [31:0] a_in = H_in[255:224], b_in = H_in[223:192], c_in = H_in[191:160], d_in = H_in[159:128];
    wire [31:0] e_in = H_in[127:96], f_in = H_in[95:64], g_in = H_in[63:32], h_in = H_in[31:0];
    reg [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;
    wire [31:0] a_d, b_d, c_d, d_d, e_d, f_d, g_d, h_d;
    wire [31:0] W_tm2, W_tm15, s1_Wtm2, s0_Wtm15, Wj, Kj;

        always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
            input_latched <= 0;
            output_valid <= 0;
        end else begin
            if (input_valid && !input_latched) begin
                // Load initial values from H_in
                a_q <= a_in; b_q <= b_in; c_q <= c_in; d_q <= d_in;
                e_q <= e_in; f_q <= f_in; g_q <= g_in; h_q <= h_in;
                round <= 0;
                input_latched <= 1;
                output_valid <= 0;
            end else if (round < 64) begin
                // Perform SHA-256 round processing
                a_q <= a_d; b_q <= b_d; c_q <= c_d; d_q <= d_d;
                e_q <= e_d; f_q <= f_d; g_q <= g_d; h_q <= h_d;
                round <= round + 1;
            end else if (round == 64) begin
                // Output valid for one cycle
                H_out <= { a_in + a_q, b_in + b_q, c_in + c_q, d_in + d_q, 
                           e_in + e_q, f_in + f_q, g_in + g_q, h_in + h_q };
                output_valid <= 1;
            end else begin
                output_valid <= 0; // Deassert output_valid in the next cycle
                input_latched <= 0; // Reset input latch
            end
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
