module mul (
    input  wire        clk,
    input  wire        rst,
    input  wire        stt, // Start signal
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] z,
    output reg        com
);

    // Valid bit tracker: 8-cycle latency
    reg [6:0] valid_pipe;
  

    // Stage 1: Input unpack
    reg [23:0] a_m1, b_m1;
    reg [9:0]  a_e1, b_e1;
    reg        a_s1, b_s1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_m1 <= 0;
            b_m1 <= 0;
            a_e1 <= 0;
            b_e1 <= 0;
            a_s1 <= 0;
            b_s1 <= 0;
        end else begin
            if (stt) begin
            // Unpack the inputs
            a_m1 <= a[22:0];
            b_m1 <= b[22:0];
            a_e1 <= a[30:23] - 127; // Bias the exponent
            b_e1 <= b[30:23] - 127; // Bias the exponent
            a_s1 <= a[31];          // Sign bit
            b_s1 <= b[31];           // Sign bit
            valid_pipe[0] <= 1; 
            
            end else begin 
                a_m1 <= 0;
            b_m1 <= 0;
            a_e1 <= 0;
            b_e1 <= 0;
            a_s1 <= 0;
            b_s1 <= 0;
            valid_pipe[0] <= 0;
        end
    end
    end

    // Stage 2: Special case & denormal handling
    reg [23:0] a_m2, b_m2;
    reg [9:0]  a_e2, b_e2;
    reg        a_s2, b_s2;
    reg [31:0] z2;
    reg        early_exit;

    always @(posedge clk) begin
        if (valid_pipe[0]) begin
        a_m2 <= a_m1;
        b_m2 <= b_m1;
        a_e2 <= a_e1;
        b_e2 <= b_e1;
        a_s2 <= a_s1;
        b_s2 <= b_s1;
        early_exit <= 0;
        z2 <= 0;
        valid_pipe[1] <= 1;

        if ((a_e1 == 128 && a_m1 != 0) || (b_e1 == 128 && b_m1 != 0)) begin
            z2 <= {1'b1, 8'hFF, 1'b1, 22'b0};  // NaN
            early_exit <= 1;
        end else if (a_e1 == 128) begin
            z2 <= {a_s1 ^ b_s1, 8'hFF, 23'b0};
            if (b_e1 == -127 && b_m1 == 0) begin
                z2 <= {1'b1, 8'hFF, 1'b1, 22'b0};  // Inf * 0 = NaN
            end
            early_exit <= 1;
        end else if (b_e1 == 128) begin
            z2 <= {a_s1 ^ b_s1, 8'hFF, 23'b0};
            if (a_e1 == -127 && a_m1 == 0) begin
                z2 <= {1'b1, 8'hFF, 1'b1, 22'b0};  // 0 * Inf = NaN
            end
            early_exit <= 1;
        end else if ((a_e1 == -127 && a_m1 == 0) || (b_e1 == -127 && b_m1 == 0)) begin
            z2 <= {a_s1 ^ b_s1, 31'b0};  // Zero result
            early_exit <= 1;
        end else begin
            if (a_e1 == -127) a_e2 <= -126; else a_m2[23] <= 1;
            if (b_e1 == -127) b_e2 <= -126; else b_m2[23] <= 1;
        end
        end else begin
            valid_pipe[1] <= 0;
        end 
    end

    // Stage 3: Normalize mantissas
    reg [23:0] a_m3, b_m3;
    reg [9:0]  a_e3, b_e3;
    reg        a_s3, b_s3;
    always @(posedge clk) begin
        if (valid_pipe[1]) begin
        a_m3 <= a_m2;
        b_m3 <= b_m2;
        a_s3 <= a_s2;
        b_s3 <= b_s2;
        a_e3 <= (~a_m2[23]) ? a_e2 - 1 : a_e2;
        b_e3 <= (~b_m2[23]) ? b_e2 - 1 : b_e2;
        if (~a_m2[23]) a_m3 <= a_m2 << 1;
        if (~b_m2[23]) b_m3 <= b_m2 << 1;
        valid_pipe[2] <= 1;
    end else valid_pipe[2] <= 0; 
    end

    // Stage 4: Multiply mantissas
    reg [49:0] product4;
    reg [9:0]  z_e4;
    reg        z_s4;
    always @(posedge clk) begin
        if (valid_pipe[2]) begin
        product4 <= a_m3 * b_m3 * 4;
        z_e4 <= a_e3 + b_e3 + 1;
        z_s4 <= a_s3 ^ b_s3;
        valid_pipe[3] <= 1;
        end else valid_pipe[3] <=0;
    end

    // Stage 5: Extract GRS bits
    reg [23:0] z_m5;
    reg        guard5, round5, sticky5;
    reg [9:0]  z_e5;
    reg        z_s5;
    always @(posedge clk) begin
        if (valid_pipe[3]) begin
        z_m5 <= product4[49:26];
        guard5  <= product4[25];
        round5  <= product4[24];
        sticky5 <= |product4[23:0];
        z_e5 <= z_e4;
        z_s5 <= z_s4;
        valid_pipe[4] <= 1;
       end else valid_pipe[4] <= 0;
    end

    // Stage 6: Normalize and round
    reg [23:0] z_m6;
    reg [9:0]  z_e6;
    reg        z_s6;
    always @(posedge clk) begin
        if (valid_pipe[4]) begin 
        z_m6 <= z_m5;
        z_e6 <= z_e5;
        z_s6 <= z_s5;
        valid_pipe[5] <= 1;

        if ($signed(z_e5) < -126) begin
            z_e6 <= z_e5 + (-126 - $signed(z_e5));
            z_m6 <= z_m5 >> (-126 - $signed(z_e5));
        end else if (~z_m5[23]) begin
            z_e6 <= z_e5 - 1;
            z_m6 <= (z_m5 << 1) | guard5;
        end else if (guard5 && (round5 | sticky5 | z_m5[0])) begin
            z_m6 <= z_m5 + 1;
            if (z_m5 == 24'hffffff)
                z_e6 <= z_e5 + 1;
        end
        end else valid_pipe[5] <= 0;
    end

    // Stage 7: Final pack
    always @(posedge clk) begin
        if (valid_pipe[5]) begin
            valid_pipe[6] <= 1;
        if (early_exit) begin
            z <= z2;
        end else begin
            z[31] <= z_s6;
            z[30:23] <= ($signed(z_e6) > 127) ? 8'hFF :
                        ($signed(z_e6) == -126 && ~z_m6[23]) ? 8'h00 :
                        z_e6[7:0] + 127;
            z[22:0] <= ($signed(z_e6) > 127) ? 0 : z_m6[22:0];
            com <= 1'b1;
        end
        end else com <= 0;
    end

endmodule
