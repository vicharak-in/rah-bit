module dct_core (
    input clk,
    input rst_n,
    input start,
    input signed [255:0] a1,
    output reg done = 0,
    output reg signed [31:0] g0, g1, g2, g3, g4, g5, g6, g7  
);

reg signed [31:0] a [0:7];

reg reset1 = 1;
reg stage = 0; // Stage register
reg stage1 = 0; // Stage register for the first stage
reg stage2 = 0; // Stage register for the second stage
reg stage3 = 0; // Stage register for the third stage
reg stage4 = 0; // Stage register for the fourth stage
reg stage5 = 0; // Stage register for the fifth stage
reg stage6 = 0; // Stage register for the sixth stage


wire [7:0] re_val_fi;
wire [6:0] re_val_se;
wire [3:0] re_val_th;
wire [5:0] re_val_fiv;
wire [3:0] re_val_si;
wire [4:0] valid ;

// Constants
parameter  m1 = 32'h3f350481;
parameter  m2 = 32'h3ec3f141;
parameter  m3 = 32'h3f0a8c15;
parameter  m4 = 32'h3fa73b64;

// Stage registers
reg signed [31:0] b0, b1, b2, b3, b4, b5, b6, b7;
reg signed [31:0] c0, c1, c2, c3, c4, c5, c6, c7;
reg signed [31:0] d0, d1, d2, d3, d4, d5, d6, d7,d8;
reg signed [31:0] e0, e1, e2, e3, e4, e5, e6, e7,e8;
reg signed [31:0] f0, f1, f2, f3, f4, f5, f6, f7;


wire signed [31:0] resu_a0, resu_a1, resu_a2, resu_a3, resu_a4, resu_a5, resu_a6, resu_a7;
wire signed [31:0] resu_b0, resu_b1, resu_b2, resu_b3, resu_b4, resu_b5, resu_b6, res_b;
wire signed [31:0] resu_c0, resu_c1, resu_c2, resu_c3, resu_c4, resu_c5, resu_c6, res_c2, res_c4, res_c5, res_c6, res_c7;
wire signed [31:0] resu_d2, resu_d3, resu_d4, resu_d6, resu_d7, res_d0, res_d1, res_d5, res_d8;
wire signed [31:0] resu_e2, resu_e3, resu_e4, resu_e5, resu_e6, resu_e7, res_e0, res_e1;
wire signed [31:0] resu_f1, resu_f3, resu_f5, resu_f7, res_f0, res_f1, res_f2, res_f3;
wire signed [31:0] resu_g1, resu_g3, resu_g5, resu_g7;
wire signed [31:0] resu_g0, resu_g2, resu_g4, resu_g6;
// Input load
always @(posedge clk ) begin
   // if (rst_n) begin
        //reset1 <= 1;
        //done <= 0;
       // stage <= 0;
   // end else begin
        case (start) 
            1:begin
            a[0] <= a1[255:224];
            a[1] <= a1[223:192];
            a[2] <= a1[191:160];
            a[3] <= a1[159:128];
            a[4] <= a1[127:96];
            a[5] <= a1[95:64];
            a[6] <= a1[63:32];
            a[7] <= a1[31:0];
            stage <= 1;
            reset1 <= 0; // Reset is low when start is high
            end 
            0: begin
            stage <= 0;
            end
            endcase
      //end
end

// Stage 1: Initial add/sub
add_sub as1_1(a[0], a[7], clk, reset1, stage, 1'b1, resu_a0, re_val_fi[0]);
add_sub as1_2(a[1], a[6], clk, reset1, stage, 1'b1, resu_a1, re_val_fi[1]);
add_sub as1_3(a[2], a[5], clk, reset1, stage, 1'b1, resu_a4, re_val_fi[2]);
add_sub as1_4(a[3], a[4], clk, reset1, stage, 1'b1, resu_a5, re_val_fi[3]);
add_sub as1_5(a[3], a[4], clk, reset1, stage, 1'b0, resu_a2, re_val_fi[4]);
add_sub as1_6(a[1], a[6], clk, reset1, stage, 1'b0, resu_a3, re_val_fi[5]);
add_sub as1_7(a[2], a[5], clk, reset1, stage, 1'b0, resu_a6, re_val_fi[6]);
add_sub as1_8(a[0], a[7], clk, reset1, stage, 1'b0, resu_a7, re_val_fi[7]);
always @(posedge clk) begin
    if (re_val_fi == 8'hff) begin
        b0 <= resu_a0;
        b1 <= resu_a1;
        b2 <= resu_a2;
        b3 <= resu_a3;
        b4 <= resu_a4;
        b5 <= resu_a5;
        b6 <= resu_a6;
        b7 <= resu_a7;
        stage1 <= 1;
    end else begin
        stage1 <= 0;
    end
end
// Stage 2 
add_sub as2_1(b0, b5, clk, reset1, stage1, 1'b1, resu_b0, re_val_se[0]);
add_sub as2_2(b1, b4, clk, reset1, stage1, 1'b0, resu_b1, re_val_se[1]);
add_sub as2_3(b2, b6, clk, reset1, stage1, 1'b1, resu_b2, re_val_se[2]);
add_sub as2_4(b1, b4, clk, reset1, stage1, 1'b1, resu_b3, re_val_se[3]);
add_sub as2_5(b3, b7, clk, reset1, stage1, 1'b1, resu_b5, re_val_se[4]);
add_sub as2_6(b0, b5, clk, reset1, stage1, 1'b0, resu_b4, re_val_se[5]);
add_sub as2_7(b3, b6, clk, reset1, stage1, 1'b1, resu_b6, re_val_se[6]);

always @(posedge clk) begin
    if (re_val_se == 7'b1111111) begin
        c0 <= resu_b0;
        c1 <= resu_b1;
        c2 <= resu_b2;                          
        c3 <= resu_b3;
        c4 <= resu_b4;
        c5 <= resu_b5;
        //c7 <= b7;
        c7 <= res_b;
        c6 <= resu_b6; // b6 is not modified in this stage
        stage2 <= 1;
    end else begin
        stage2 <= 0;
    end
end
buff buff1 (clk, reset1, stage1, b7, res_b);
// Stage 3
add_sub as3_1(c0, c3, clk, reset1, stage2, 1'b1, resu_c0, re_val_th[0]);
add_sub as3_2(c0, c3, clk, reset1, stage2, 1'b0, resu_c1, re_val_th[1]);
add_sub as3_4(c1, c4, clk, reset1, stage2, 1'b1, resu_c3, re_val_th[2]);
add_sub as3_5(c2, c5, clk, reset1, stage2, 1'b0, resu_c4, re_val_th[3]);

always @(posedge clk) begin
    if (re_val_th == 4'hf) begin
        d0 <= resu_c0;
        d1 <= resu_c1;
        d2 <= res_c2;
        d3 <= resu_c3;
        d4 <= resu_c4;
        d5 <= res_c4; // c4 is not modified in this stage
        d6 <= res_c5; // c5 is not modified in this stage
        d7 <= res_c6; // c6 is not modified in this stage
        d8 <= res_c7; // c7 is not modified in this stage
        stage3 <= 1;
    end else stage3 <= 0;
end
buff buff12 (clk, reset1, stage2, c2, res_c2);
buff buff13 (clk, reset1, stage2, c4, res_c4);
buff buff14 (clk, reset1, stage2, c5, res_c5);
buff buff15 (clk, reset1, stage2, c6, res_c6);
buff buff16 (clk, reset1, stage2, c7, res_c7);
// Stage 4: Mul stage
mul m4_1(clk, reset1, stage3, m3, d2, resu_d2, valid[0]);
mul m4_2(clk, reset1, stage3, m1, d7, resu_d3, valid[1]);
mul m4_3(clk, reset1, stage3, m4, d6, resu_d4, valid[2]);
mul m4_4(clk, reset1, stage3, m1, d3, resu_d6, valid[3]);
mul m4_5(clk, reset1, stage3, m2, d4, resu_d7, valid[4]);
always @(posedge clk) begin
    if (valid == 5'b11111) begin
        e0 <= res_d0;
        e1 <= res_d1;
        e2 <= resu_d2;
        e3 <= resu_d3;
        e4 <= resu_d4;
        e5 <= res_d5; // d5 is not modified in this stage
        e6 <= resu_d6; // d6 is not modified in this stage
        e7 <= resu_d7; // d7 is not modified in this stage
        e8 <= res_d8; // d8 is not modified in this stage
        stage4 <= 1;
    end else begin
        stage4 <= 0;
    end
end
buff_mul buff2 (clk, reset1, stage3, d0, res_d0);
buff_mul buff3 (clk, reset1, stage3, d1, res_d1);
buff_mul buff4 (clk, reset1, stage3, d5, res_d5);
buff_mul buff5 (clk, reset1, stage3, d8, res_d8);

// Stage 5

add_sub as5_1(e5, e6, clk, reset1, stage4, 1'b1, resu_e2, re_val_fiv[0]);
add_sub as5_2(e5, e6, clk, reset1, stage4, 1'b0, resu_e3, re_val_fiv[1]);
add_sub as5_3(e3, e8, clk, reset1, stage4, 1'b1, resu_e4, re_val_fiv[2]);
add_sub as5_4(e8, e3, clk, reset1, stage4, 1'b0, resu_e5, re_val_fiv[3]);
add_sub as5_5(e2, e7, clk, reset1, stage4, 1'b1, resu_e6, re_val_fiv[4]);
add_sub as5_6(e4, e7, clk, reset1, stage4, 1'b1, resu_e7, re_val_fiv[5]);
always @(posedge clk) begin
    if (re_val_fiv == 6'b111111) begin
        f0 <= res_e0;
        f1 <= res_e1;
        f2 <= resu_e2;
        f3 <= resu_e3;
        f4 <= resu_e4;
        f5 <= resu_e5; // e5 is not modified in this stage
        f6 <= resu_e6; // e6 is not modified in this stage
        f7 <= resu_e7; // e7 is not modified in this stage
        stage5 <= 1;
    end else begin
        stage5 <= 0;
    end
end
buff buff6 (clk, reset1, stage4, e0, res_e0);
buff buff7 (clk, reset1, stage4, e1, res_e1);
// Stage 6

add_sub as6_1(f4, f7, clk, reset1, stage5, 1'b1, resu_f1, re_val_si[0]);                                    
add_sub as6_3(f6, f5, clk, reset1, stage5, 1'b1, resu_f5, re_val_si[1]);
add_sub as6_5(f5,f6,  clk, reset1, stage5, 1'b0, resu_f3, re_val_si[2]);
add_sub as6_6(f4, f7, clk, reset1, stage5, 1'b0, resu_f7, re_val_si[3]);

 always @(posedge clk) begin
    if (re_val_si[3:0] == 4'hf) begin
            g0 <= res_f0;
            g2 <= res_f2;
            g4 <= res_f1;
            g6 <= res_f3; 
            g1 <= resu_f1;
            g3 <= resu_f3;
            g5 <= resu_f5; 
            g7 <= resu_f7; 
            stage6 <= 1;
            done <= 1;
    end else begin
        stage6 <= 0;
         done <= 0;
    end
end
buff buff8 (clk, reset1, stage5, f0, res_f0);
buff buff9 (clk, reset1, stage5, f1, res_f1);
buff buff10 (clk, reset1, stage5, f3, res_f3);
buff buff11 (clk, reset1, stage5, f2, res_f2);

endmodule
