`timescale 1ns / 1ps
/*  IEEE754 32-bit floating point format: -1^(sign) * 2^(exponent-127) * (1+M/2^23)     */

module float_to_fixed#(
    parameter FLOAT_FMT ="byte_10" ,
    parameter INT_WID =40  ,
    parameter FRA_WID =40 ,

    /*  parameters below should not be overwritten  */
    parameter FLOAT_WID = FLOAT_FMT == "float" ? 32 : FLOAT_FMT == "double" ? 64 :FLOAT_FMT == "byte_10" ? 80 : 0
) (
    input                             clk,
    input                             rstn,
    input                             clk_en,
    input             [FLOAT_WID-1:0] float_val,
`ifdef SIM
    output reg        [FLOAT_WID-1:0] float_val_echo = 0,
`endif //SIM

    output reg                        overflow = 0,
    output reg                        underflow = 0,
    output reg                        nan = 0,
    output reg                        infinity = 0,
    output reg                        denorm = 0,
    output reg                        zero = 0,
    output reg        [  FRA_WID-1:0] fixed_fraction = 0,
    output reg signed [  INT_WID-1:0] fixed_integer = 0,
    output reg                        done
);
`ifndef SIM
reg [FLOAT_WID-1:0] float_val_echo = 0;
`endif //SIM

//reg [FLOAT_WID-1:0] float_val= 32'h41E053C8;
reg [3:0] count=0;
localparam SIGN_BIT = FLOAT_FMT == "float" ? 31 : FLOAT_FMT == "double" ? 63 : FLOAT_FMT == "byte_10" ? 79 :0;
localparam EXP_WID = FLOAT_FMT == "float" ? 8 : FLOAT_FMT == "double" ? 11 : FLOAT_FMT == "byte_10" ? 15 : 0;
localparam MANT_WID = FLOAT_FMT == "float" ? 23 : FLOAT_FMT == "double" ? 52 :FLOAT_FMT == "byte_10" ? 64 : 0;
localparam EXP_BIAS = FLOAT_FMT == "float" ? 8'd127 : FLOAT_FMT == "double" ? 11'd1023 : FLOAT_FMT == "byte_10" ? 15'd16383 : 0;

localparam EXP_UPPER_BOUND = INT_WID-1-1; //the first -1 due to 2's complement, last -1 due to the leading 1 
localparam EXP_LOWER_BOUND = FRA_WID + 1;  //+1 due to the leading 1
localparam SHIFT_RNG = EXP_UPPER_BOUND + EXP_LOWER_BOUND;
localparam SHIFT_RNG_WID = $clog2(SHIFT_RNG + 1);

localparam [0:0] MIN_FLOAT_SIGN = 1'd1;
localparam [7:0] MIN_FLOAT_EXPONENT = EXP_BIAS - 1'b1 + INT_WID;
localparam [22:0] MIN_FLOAT_MANTISSA = 23'd0;
localparam [31:0] MIN_FLOAT_VALUE = {MIN_FLOAT_SIGN, MIN_FLOAT_EXPONENT, MIN_FLOAT_MANTISSA};
localparam [0:0] MIN_DOUBLE_SIGN = 1'd1;
localparam [10:0] MIN_DOUBLE_EXPONENT = EXP_BIAS - 1'b1 + INT_WID;
localparam [51:0] MIN_DOUBLE_MANTISSA = 52'd0;
localparam [63:0] MIN_DOUBLE_VALUE = {
    MIN_DOUBLE_SIGN, MIN_DOUBLE_EXPONENT, MIN_DOUBLE_MANTISSA
};
localparam MIN_VALUE = FLOAT_FMT == "float" ? MIN_FLOAT_VALUE : 
                    FLOAT_FMT == "double" ? MIN_DOUBLE_VALUE :
                    0;

localparam NUM_SHIFT_WID_1ST = $rtoi($floor(SHIFT_RNG_WID / 3.0));
localparam SHIFT_BIT_WID_2ND = SHIFT_RNG_WID - NUM_SHIFT_WID_1ST;
localparam NUM_SHIFT_WID_2ND = $rtoi($floor((SHIFT_RNG_WID - NUM_SHIFT_WID_1ST) / 2.0));
localparam SHIFT_BIT_WID_LAST = SHIFT_BIT_WID_2ND - NUM_SHIFT_WID_2ND;
localparam DATA_SHIFT_WID_1ST = (1 << NUM_SHIFT_WID_1ST) - 1;
localparam DATA_SHIFT_WID_2ND = (1 << (NUM_SHIFT_WID_1ST + NUM_SHIFT_WID_2ND)) - 1 - DATA_SHIFT_WID_1ST;
localparam DATA_SHIFT_WID_LAST = (1 << SHIFT_RNG_WID) - 1 - DATA_SHIFT_WID_1ST - DATA_SHIFT_WID_2ND;

localparam REM_WID = MANT_WID + 1;
localparam STORE_WID_R1 = REM_WID + DATA_SHIFT_WID_1ST;
localparam STORE_WID_R2 = STORE_WID_R1 + DATA_SHIFT_WID_2ND;
localparam STORE_WID_LAST = STORE_WID_R2 + DATA_SHIFT_WID_LAST;

localparam FRA_PART_WID_R3 = $rtoi($floor((FRA_WID*0.25)));

wire sign;
wire [EXP_WID-1:0] exponent;
wire [MANT_WID-1:0] mantissa;

assign sign     = float_val[SIGN_BIT];
assign exponent = float_val[MANT_WID+:EXP_WID];
assign mantissa = float_val[0+:MANT_WID];

/*  stage_0     */
reg [STORE_WID_R1-1:0]      mantissa_r1 = 0;
reg [SHIFT_BIT_WID_2ND-1:0] shift_bit_r1 = 0;
reg [FLOAT_WID-1:0]         float_val_echo_r1 = 0;
reg                         sign_r1 = 0;  //0=pos, 1=neg
reg                         overflow_r1 = 0;
reg                         underflow_r1 = 0;
reg                         nan_r1 = 0;
reg                         zero_r1 = 0;
reg                         inf_r1 = 0;
reg                         denorm_r1 = 0;
reg                         min_r1 = 0;
wire [SHIFT_RNG_WID-1:0] shift_range;
assign shift_range = exponent - (EXP_BIAS - EXP_LOWER_BOUND);

/*  stage_1     */
reg  [       STORE_WID_R2-1:0] mantissa_r2 = 0;
reg  [ SHIFT_BIT_WID_LAST-1:0] shift_bit_r2 = 0;
reg  [          FLOAT_WID-1:0] float_val_echo_r2 = 0;
reg                            sign_r2 = 0;
reg                            nan_r2 = 0;
reg                            inf_r2 = 0;
reg                            denorm_r2 = 0;
reg                            zero_r2 = 0;
reg                            result_clr_r2 = 0;
reg                            result_set_r2 = 0;
reg                            overflow_r2 = 0;
reg                            underflow_r2 = 0;

/*  stage_2     */
reg  [          FLOAT_WID-1:0]  float_val_echo_r3 = 0;
reg                             overflow_r3 = 0;
reg                             underflow_r3 = 0;
reg                             sign_r3 = 0;
reg                             nan_r3 = 0;
reg                             inf_r3 = 0;
reg                             denorm_r3 = 0;
reg                             zero_r3 = 0;
reg                             result_clr_r3 = 0;
reg                             result_set_r3 = 0;
reg [FRA_PART_WID_R3+1-1:0]     fraction_part_r3 = 0;
reg [INT_WID+(FRA_WID+1)-1:0]   mantissa_r3 = 0;

wire  [     STORE_WID_LAST-1:0] mantissa_shift_r3;
wire [INT_WID+(FRA_WID+1)-1:0]  mantissa_cut_r3;
assign mantissa_shift_r3 = {{DATA_SHIFT_WID_LAST{1'b0}}, mantissa_r2} << {shift_bit_r2[0+:SHIFT_BIT_WID_LAST], {(NUM_SHIFT_WID_2ND+NUM_SHIFT_WID_1ST){1'b0}}};
assign mantissa_cut_r3 = {1'b0, mantissa_shift_r3[REM_WID-1+:(INT_WID-1)+(FRA_WID+1)]};

/*  stage_3     */
reg [FLOAT_WID-1:0] float_val_echo_r4 = 0;
reg                 overflow_r4 = 0;
reg                 underflow_r4 = 0;
reg                 sign_r4 = 0;
reg                 nan_r4 = 0;
reg                 inf_r4 = 0;
reg                 denorm_r4 = 0;
reg                 zero_r4 = 0;
reg                 result_clr_r4 = 0;
reg                 result_set_r4 = 0;
reg [  INT_WID-1:0] fixed_integer_r4 = 0;
reg [  FRA_WID-1:0] fixed_fraction_r4 = 0;
reg [    FRA_WID:0] fixed_fraction_r4_twos = 0;
reg [    FRA_WID:0] fraction_round_comb_r4 = 0;
reg [  INT_WID-1:0] integer_comb_r4 = 0;

/*  stage_4     */
reg [  FRA_WID-1:0] fixed_fraction_r5_comb = 0;
reg [  INT_WID-1:0] fixed_integer_r5_comb = 0;

generate
    if (NUM_SHIFT_WID_1ST == 0) begin
        always @(posedge clk or negedge rstn) begin : stage_1_mantissa
            if (~rstn) begin
                mantissa_r1 <= 0;
            end else if (clk_en) begin
                mantissa_r1 <= {1'b1, mantissa};
            end
        end
    end else begin
        always @(posedge clk or negedge rstn) begin : stage_1_mantissa
            if (~rstn) begin
                mantissa_r1 <= 0;
            end else if (clk_en) begin
                mantissa_r1  <= {{DATA_SHIFT_WID_1ST{1'b0}}, 1'b1, mantissa} << shift_range[0+:NUM_SHIFT_WID_1ST];
            end
        end
    end
endgenerate


always @(posedge clk or negedge rstn) begin : stage_1
    if (~rstn) begin
        shift_bit_r1 <= 0;
        float_val_echo_r1 <= 0;
        sign_r1 <= 0;
        overflow_r1 <= 0;
        underflow_r1 <= 0;
        nan_r1 <= 0;
        zero_r1 <= 0;
        inf_r1 <= 0;
        denorm_r1 <= 0;
        min_r1 <= 0;
    end else if (clk_en) begin
        float_val_echo_r1 <= float_val;
        if (exponent == {EXP_WID{1'b0}} && mantissa == {MANT_WID{1'b0}}) zero_r1 <= 1;
        else zero_r1 <= 0;

        if (exponent == {EXP_WID{1'b0}} && mantissa != {MANT_WID{1'b0}}) denorm_r1 <= 1;
        else denorm_r1 <= 0;

        if (exponent == {EXP_WID{1'b1}} && mantissa != {MANT_WID{1'b0}}) nan_r1 <= 1;
        else nan_r1 <= 0;

        if (exponent == {EXP_WID{1'b1}} && mantissa == {MANT_WID{1'b0}}) inf_r1 <= 1;
        else inf_r1 <= 0;

        sign_r1      <= sign;

        /** shift_bit should less than 32 and larger than 0.
        * if exceed this range, handled by overflow/underflow flag
        **/
        shift_bit_r1 <= shift_range[NUM_SHIFT_WID_1ST+:SHIFT_BIT_WID_2ND];

        min_r1       <= 0;
        if (exponent > EXP_UPPER_BOUND + EXP_BIAS) begin
            if (float_val == MIN_VALUE) begin
                overflow_r1 <= 0;
                min_r1      <= 1;
            end else begin
                overflow_r1 <= 1;
            end
        end else begin
            overflow_r1 <= 0;
        end

        if (EXP_BIAS - EXP_LOWER_BOUND > exponent) underflow_r1 <= 1;
        else underflow_r1 <= 0;
        if(count<7)begin
            done=0;
            count=count+1;
        end
         else if(count==7)begin
             done=1;
             count=count+1;
        end
        else if(INT_WID==16 && count==8)begin
            done=0;
            count=count+1;
        end
        else if((INT_WID==32 ||INT_WID==40) && count==8)begin
            done=1;
            count=count+1;
        end
        else if(count>8)begin
            done=0;
        end
    end
    else if(!clk_en)count=0;
end


generate
    if (NUM_SHIFT_WID_2ND == 0) begin
        always @(posedge clk or negedge rstn) begin : stage_2_mantissa
            if (~rstn) begin
                mantissa_r2 <= 0;
            end else if (clk_en) begin
                mantissa_r2 <= mantissa_r2;
            end
        end
    end else begin
        always @(posedge clk or negedge rstn) begin : stage_2_mantissa
            if (~rstn) begin
                mantissa_r2 <= 0;
            end else if (clk_en) begin
                mantissa_r2  <= {{DATA_SHIFT_WID_2ND{1'b0}}, mantissa_r1} << {shift_bit_r1[0+:NUM_SHIFT_WID_2ND], {NUM_SHIFT_WID_1ST{1'b0}}};
            end
        end
    end
endgenerate

always @(posedge clk or negedge rstn) begin : stage_2
    if (~rstn) begin
        shift_bit_r2 <= 0;
        float_val_echo_r2 <= 0;
        sign_r2 <= 0;
        nan_r2 <= 0;
        inf_r2 <= 0;
        denorm_r2 <= 0;
        zero_r2 <= 0;
        result_clr_r2 <= 0;
        result_set_r2 <= 0;
        overflow_r2 <= 0;
        underflow_r2 <= 0;
    end else if (clk_en) begin
        float_val_echo_r2 <= float_val_echo_r1;
        nan_r2            <= nan_r1;
        zero_r2           <= zero_r1;
        inf_r2            <= inf_r1;
        sign_r2           <= sign_r1;
        denorm_r2         <= denorm_r1;
        overflow_r2       <= overflow_r1;
        underflow_r2      <= underflow_r1;

        if (zero_r1 | nan_r1 | denorm_r1 | underflow_r1)  //output clear
            result_clr_r2 <= 1;
        else result_clr_r2 <= 0;

        if (inf_r1 | overflow_r1 | min_r1) result_set_r2 <= 1;
        else result_set_r2 <= 0;

        shift_bit_r2 <= shift_bit_r1[NUM_SHIFT_WID_2ND+:SHIFT_BIT_WID_LAST];
    end
end


generate
    if (FRA_PART_WID_R3 == 0) begin
        always @(posedge clk or negedge rstn) begin : stage_3_fraction
            if (~rstn)
                fraction_part_r3 <= 0;
            else 
                fraction_part_r3 <= {1'b0, mantissa_cut_r3[0]};
        end
    end else begin
        always @(posedge clk or negedge rstn) begin : stage_3_fraction
            if (~rstn)
                fraction_part_r3 <= 0;
            else 
                fraction_part_r3 <= {1'b0, mantissa_cut_r3[1+:FRA_PART_WID_R3]} + mantissa_cut_r3[0];
        end
    end
endgenerate

always @(posedge clk or negedge rstn) begin : stage_3
    if (~rstn) begin
        float_val_echo_r3 <= 0;
        overflow_r3 <= 0;
        underflow_r3 <= 0;
        sign_r3 <= 0;
        nan_r3 <= 0;
        inf_r3 <= 0;
        denorm_r3 <= 0;
        zero_r3 <= 0;
        result_clr_r3 <= 0;
        result_set_r3 <= 0;
        mantissa_r3 <= 0;
    end else if (clk_en) begin
        float_val_echo_r3 <= float_val_echo_r2;
        overflow_r3 <= overflow_r2;
        underflow_r3 <= underflow_r2;
        sign_r3 <= sign_r2;
        nan_r3 <= nan_r2;
        zero_r3 <= zero_r2;
        inf_r3 <= inf_r2;
        denorm_r3 <= denorm_r2;
        result_clr_r3 <= result_clr_r2;
        result_set_r3 <= result_set_r2;
        
        mantissa_r3 <= mantissa_cut_r3;
    end
end


generate
    if (FRA_PART_WID_R3 != 0) begin
        always @(*) begin : stage_4_comb
            fraction_round_comb_r4  = {{1'b0, mantissa_r3[FRA_PART_WID_R3+1 +: (FRA_WID-FRA_PART_WID_R3)] } + fraction_part_r3[FRA_PART_WID_R3], 
                                    fraction_part_r3[0+:FRA_PART_WID_R3]};
            integer_comb_r4 = mantissa_r3[FRA_WID+1 +: INT_WID];
        end
    end else begin
        always @(*) begin : stage_4_comb
            fraction_round_comb_r4  = {{1'b0, mantissa_r3[FRA_PART_WID_R3+1 +: (FRA_WID-FRA_PART_WID_R3)] } + fraction_part_r3[FRA_PART_WID_R3]};
            integer_comb_r4 = mantissa_r3[FRA_WID+1 +: INT_WID];
        end
    end
endgenerate

always @(posedge clk or negedge rstn) begin : stage_4
    if (~rstn) begin
        float_val_echo_r4 <= 0;
        overflow_r4 <= 0;
        underflow_r4 <= 0;
        sign_r4 <= 0;
        nan_r4 <= 0;
        inf_r4 <= 0;
        denorm_r4 <= 0;
        zero_r4 <= 0;
        result_clr_r4 <= 0;
        result_set_r4 <= 0;
        fixed_integer_r4 <= 0;
        fixed_fraction_r4 <= 0;
        fixed_fraction_r4_twos <= 0;
    end else if (clk_en) begin
        float_val_echo_r4 <= float_val_echo_r3;
        overflow_r4 <= overflow_r3;
        underflow_r4 <= underflow_r3;
        sign_r4 <= sign_r3;
        nan_r4 <= nan_r3;
        zero_r4 <= zero_r3;
        inf_r4 <= inf_r3;
        denorm_r4 <= denorm_r3;
        result_clr_r4 <= result_clr_r3;
        result_set_r4 <= result_set_r3;

        fixed_integer_r4 <= integer_comb_r4 + fraction_round_comb_r4[FRA_WID]; //add carry in from fractional part
        fixed_fraction_r4 <= fraction_round_comb_r4[0+:FRA_WID];
        fixed_fraction_r4_twos <= {1'b0, ~(fraction_round_comb_r4[0+:FRA_WID])} + 1'b1;
    end
end


always @(*) begin : stage_5_comb
    if (sign_r4)
        /*  no need to add 1'b1 to ~fixed_integer_r5_comb because output format is (+/-integer) + (+fraction), 
         *  only add when fractional part overflow    
         **/
        fixed_integer_r5_comb = ~(fixed_integer_r4) + fixed_fraction_r4_twos[FRA_WID];
    else fixed_integer_r5_comb = (fixed_integer_r4);

    if (sign_r4) fixed_fraction_r5_comb = fixed_fraction_r4_twos[0+:FRA_WID];
    else fixed_fraction_r5_comb = (fixed_fraction_r4[0+:FRA_WID]);
end

always @(posedge clk or negedge rstn) begin : stage_5
    if (~rstn) begin
        float_val_echo <= 0;
        overflow       <= 0;
        underflow      <= 0;
        nan            <= 0;
        infinity       <= 0;
        denorm         <= 0;
        zero           <= 0;
        fixed_fraction <= 0;
        fixed_integer  <= 0;
    end else if (clk_en) begin
        float_val_echo <= float_val_echo_r4;
        nan            <= nan_r4;
        infinity       <= inf_r4;
        denorm         <= denorm_r4;
        zero           <= zero_r4;

        if (inf_r4) begin
            overflow  <= 1;
            underflow <= 0;
        end else if (zero_r4 | nan_r4 | denorm_r4) begin
            overflow  <= 0;
            underflow <= 0;
        end else begin
            overflow  <= overflow_r4;
            underflow <= underflow_r4;
        end

        if (result_clr_r4) begin
            fixed_integer  <= 0;
            fixed_fraction <= 0;
        end else if (result_set_r4) begin  // maximum/minimum
            fixed_integer  <= {1'b0, {(INT_WID - 1) {1'b1}}} + sign_r4;
            fixed_fraction <= {FRA_WID{1'b1}} + sign_r4;
        end else begin
            if (!sign_r4 && fixed_integer_r5_comb[INT_WID-1]) begin  //positive overflow
                fixed_integer  <= {1'b0, {(INT_WID - 1) {1'b1}}};
                fixed_fraction <= {FRA_WID{1'b1}};
            end else begin
                fixed_integer  <= fixed_integer_r5_comb;
                fixed_fraction <= fixed_fraction_r5_comb;
            end
        end
    end
end

endmodule
