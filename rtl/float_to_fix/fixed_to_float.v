module fixed_to_float#(
    parameter FLOAT_FMT ="byte_10" ,
    parameter INT_WID =40  ,
    parameter FRA_WID =40 ,

    /*  parameters below should not be overwritten  */
    parameter FLOAT_WID = FLOAT_FMT == "float" ? 32 : FLOAT_FMT == "double" ? 64 :FLOAT_FMT == "byte_10" ? 80 : 0
) (
    input                          clk,
    input                          rstn,
    input                          clk_en,
    input        [FRA_WID-1:0] fixed_fraction,
    input signed [INT_WID-1:0] fixed_integer,

`ifdef SIM
    output reg        [FRA_WID-1:0] fixed_fraction_echo = 0,
    output reg signed [INT_WID-1:0] fixed_integer_echo = 0,
`endif  //SIM

    output [FLOAT_WID-1:0] float_val,
    output reg             done
);

reg [3:0] count=0;
localparam SIGN_BIT = FLOAT_FMT == "float" ? 31 : FLOAT_FMT == "double" ? 63 : FLOAT_FMT == "byte_10" ? 79 :0;
localparam EXP_WID = FLOAT_FMT == "float" ? 8 : FLOAT_FMT == "double" ? 11 : FLOAT_FMT == "byte_10" ? 15 : 0;
localparam MANT_WID = FLOAT_FMT == "float" ? 23 : FLOAT_FMT == "double" ? 52 :FLOAT_FMT == "byte_10" ? 64 : 0;
localparam EXP_BIAS = FLOAT_FMT == "float" ? 8'd127 : FLOAT_FMT == "double" ? 11'd1023 : FLOAT_FMT == "byte_10" ? 15'd16383 : 0;
localparam FLOAT_EXP_START_PT = EXP_BIAS - (FRA_WID);

localparam SHIFT_RNG = INT_WID + FRA_WID;
localparam SHIFT_RNG_WID = $clog2(SHIFT_RNG);
localparam EXTEND_RNG = (1 << SHIFT_RNG_WID);
localparam MAX_SHIFT_RNG = EXTEND_RNG - 1;
localparam NUM_PAD = EXTEND_RNG - SHIFT_RNG;

/*  stage_0 parameter   */
localparam NUM_SHIFT_WID_1ST = $rtoi($floor(SHIFT_RNG_WID / 3.0));
localparam NUM_SHIFT_REM_WID_1ST = SHIFT_RNG_WID - NUM_SHIFT_WID_1ST;
localparam NUM_BLK_1ST = 1 << NUM_SHIFT_WID_1ST;
localparam BLOCK_WID_1ST = 1 << NUM_SHIFT_REM_WID_1ST;
localparam ACC_SHIFT_RNG_1ST = (1 << SHIFT_RNG_WID) - (1 << (NUM_SHIFT_REM_WID_1ST));
localparam MAX_SHIFT_BLK_1ST = (SHIFT_RNG - 1) / BLOCK_WID_1ST;

localparam NUM_SHIFT_WID_2ND = $rtoi($floor((SHIFT_RNG_WID - NUM_SHIFT_WID_1ST) / 2.0));
localparam NUM_SHIFT_REM_WID_2ND = NUM_SHIFT_REM_WID_1ST - NUM_SHIFT_WID_2ND;
localparam NUM_BLK_2ND = 1 << NUM_SHIFT_WID_2ND;
localparam BLOCK_WID_2ND = 1 << NUM_SHIFT_REM_WID_2ND;
localparam ACC_SHIFT_RNG_2ND = ACC_SHIFT_RNG_1ST + (1<<NUM_SHIFT_REM_WID_1ST) - (1<<NUM_SHIFT_REM_WID_2ND);

localparam NUM_SHIFT_WID_LAST = NUM_SHIFT_REM_WID_2ND;
localparam NUM_BLK_LAST = 1 << NUM_SHIFT_WID_LAST;
localparam BLOCK_WID_LAST = 1 << 0;

localparam ADD_PARTIAL = 16;
localparam NUM_PAD_BACK = (MANT_WID - MAX_SHIFT_RNG) >= 0 ? MANT_WID - MAX_SHIFT_RNG + 1 : 0;

/*  stage_0 */
wire [EXTEND_RNG-1:0] fixed;
wire                  sign;
wire                  zero;
assign fixed = {{NUM_PAD{sign}}, fixed_integer, fixed_fraction};
assign sign  = fixed_integer[INT_WID-1];
assign zero  = (fixed_fraction == 0 && fixed_integer == 0) ? 1 : 0;

/*  stage_1 */
reg        [                    NUM_SHIFT_WID_1ST-1:0] shift_bit_r1_comb;
reg        [                           EXTEND_RNG-1:0] fixed_r1 = 0;
reg        [                              FRA_WID-1:0] fixed_fraction_echo_r1 = 0;
reg signed [                              INT_WID-1:0] fixed_integer_echo_r1 = 0;
reg                                                    zero_r1 = 1;
reg                                                    sign_r1 = 0;
reg        [                    NUM_SHIFT_WID_1ST-1:0] shift_bit_r1 = 0;

/*  stage_2 */
reg        [                          NUM_BLK_2ND-1:0] shift_flag_r2_comb;
reg        [         EXTEND_RNG+ACC_SHIFT_RNG_1ST-1:0] mantissa_r2_comb;
reg        [         EXTEND_RNG+ACC_SHIFT_RNG_1ST-1:0] mantissa_r2_again_comb;
reg        [                    NUM_SHIFT_WID_2ND-1:0] shift_bit_r2_comb;
reg                                                    shift_again_r2_comb;
reg        [                          NUM_BLK_2ND-1:0] shift_flag_r2 = 0;
reg                                                    sign_r2 = 0;
reg        [         EXTEND_RNG+ACC_SHIFT_RNG_1ST-1:0] mantissa_r2 = 0;
reg        [                              EXP_WID-1:0] float_exp_r2 = 0;
reg        [                              FRA_WID-1:0] fixed_fraction_echo_r2 = 0;
reg signed [                              INT_WID-1:0] fixed_integer_echo_r2 = 0;

/*  stage_3 */
reg        [       EXTEND_RNG + ACC_SHIFT_RNG_2ND-1:0] mantissa_r3_comb;
reg        [                   NUM_SHIFT_WID_LAST-1:0] shift_bit_r3_comb;
reg                                                    sign_r3 = 0;
reg        [       EXTEND_RNG + ACC_SHIFT_RNG_2ND-1:0] mantissa_r3 = 0;
reg        [                   NUM_SHIFT_WID_LAST-1:0] shift_bit_r3 = 0;
reg        [                              EXP_WID-1:0] float_exp_r3 = 0;
reg        [                              FRA_WID-1:0] fixed_fraction_echo_r3 = 0;
reg signed [                              INT_WID-1:0] fixed_integer_echo_r3 = 0;

/*  stage_4 */
reg        [EXTEND_RNG+MAX_SHIFT_RNG+NUM_PAD_BACK-1:0] mantissa_r4_comb;
reg        [EXTEND_RNG+MAX_SHIFT_RNG+NUM_PAD_BACK-1:0] mantissa_r4_inv_comb;
reg                                                    sign_r4 = 0;
reg        [                 MANT_WID-ADD_PARTIAL-1:0] mantissa_r4_msb = 0;
reg        [                            ADD_PARTIAL:0] mantissa_r4_lsb = 0;
reg        [                              EXP_WID-1:0] float_exp_r4 = 0;
reg        [                              FRA_WID-1:0] fixed_fraction_echo_r4 = 0;
reg signed [                              INT_WID-1:0] fixed_integer_echo_r4 = 0;

/*  stage_5 */
reg        [                               MANT_WID:0] mantissa_round_r5_comb;
reg                                                    float_sign_r5 = 0;
reg        [                              EXP_WID-1:0] float_exp_r5 = 0;
reg        [                             MANT_WID-1:0] float_mant_r5 = 0;
assign float_val = {float_sign_r5, float_exp_r5, float_mant_r5};
`ifndef SIM
/*  optimized out if not doing simulation */
reg        [FRA_WID-1:0] fixed_fraction_echo = 0;
reg signed [INT_WID-1:0] fixed_integer_echo = 0;
`endif  //SIM

always @(*) begin : stage_1_comb
    shift_bit_r1_comb = 0;
    for (integer i = 1; i < NUM_BLK_1ST; i = i + 1) begin
        if (fixed[i*BLOCK_WID_1ST+:BLOCK_WID_1ST] != {BLOCK_WID_1ST{sign}}) begin
            shift_bit_r1_comb = i;
        end
    end
end

always @(posedge clk or negedge rstn) begin : stage_1
    if (~rstn) begin
        fixed_r1               <= 0;
        fixed_fraction_echo_r1 <= 0;
        fixed_integer_echo_r1  <= 0;
        zero_r1                <= 1;
        sign_r1                <= 0;
        shift_bit_r1           <= 0;
    end else if (clk_en) begin
        fixed_fraction_echo_r1 <= fixed_fraction;
        fixed_integer_echo_r1  <= fixed_integer;
        zero_r1                <= zero;
        sign_r1                <= sign;
        fixed_r1               <= fixed - sign;
        shift_bit_r1           <= shift_bit_r1_comb;
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


always @(*) begin : stage_2_comb
    mantissa_r2_comb = ({fixed_r1, {ACC_SHIFT_RNG_1ST{sign_r1}}}) >> 
                        {shift_bit_r1, {NUM_SHIFT_REM_WID_1ST{1'd0}}};

    if (sign_r1 != mantissa_r2_comb[ACC_SHIFT_RNG_1ST + NUM_BLK_2ND*BLOCK_WID_2ND] && shift_bit_r1 != MAX_SHIFT_BLK_1ST) begin
        mantissa_r2_again_comb = mantissa_r2_comb >> {1'b1, {NUM_SHIFT_REM_WID_1ST{1'd0}}};
        shift_again_r2_comb = 1;
    end else begin
        mantissa_r2_again_comb = mantissa_r2_comb;
        shift_again_r2_comb = 0;
    end

    for (integer i = 1; i < NUM_BLK_2ND; i = i + 1) begin
        if (mantissa_r2_again_comb[ACC_SHIFT_RNG_1ST + i*BLOCK_WID_2ND+:BLOCK_WID_2ND] != {BLOCK_WID_2ND{sign_r1}}) begin
            shift_flag_r2_comb[i] = 1;
        end else begin
            shift_flag_r2_comb[i] = 0;
        end
    end
end

always @(posedge clk or negedge rstn) begin : stage_2
    if (~rstn) begin
        shift_flag_r2          <= 0;
        sign_r2                <= 0;
        mantissa_r2            <= 0;
        float_exp_r2           <= 0;
        fixed_fraction_echo_r2 <= 0;
        fixed_integer_echo_r2  <= 0;
    end else if (clk_en) begin
        fixed_fraction_echo_r2  <= fixed_fraction_echo_r1;
        fixed_integer_echo_r2   <= fixed_integer_echo_r1;
        sign_r2                 <= sign_r1;
        mantissa_r2             <= mantissa_r2_again_comb;
        float_exp_r2            <= zero_r1 ? {shift_bit_r1, {NUM_SHIFT_REM_WID_1ST{1'd0}}} : 
                                    FLOAT_EXP_START_PT + {shift_bit_r1 + shift_again_r2_comb, {NUM_SHIFT_REM_WID_1ST{1'd0}}};
        shift_flag_r2           <= shift_flag_r2_comb;
    end
end


always @(*) begin : stage_3_comb
    shift_bit_r2_comb = 0;
    for (integer i = 1; i < NUM_BLK_2ND; i = i + 1) begin
        if (shift_flag_r2[i]) begin
            shift_bit_r2_comb = i;
        end
    end

    mantissa_r3_comb = {
        (mantissa_r2), 
        {(ACC_SHIFT_RNG_2ND - ACC_SHIFT_RNG_1ST){sign_r2}}
    } >> {shift_bit_r2_comb, {{NUM_SHIFT_REM_WID_2ND{1'd0}}}};

    shift_bit_r3_comb = 0;
    for (integer i = 1; i < NUM_BLK_LAST; i = i + 1) begin
        if (mantissa_r3_comb[ACC_SHIFT_RNG_2ND+i*BLOCK_WID_LAST+:BLOCK_WID_LAST] != sign_r2) begin
            shift_bit_r3_comb = i;
        end
    end
end

always @(posedge clk or negedge rstn) begin : stage_3
    if (~rstn) begin
        sign_r3                <= 0;
        mantissa_r3            <= 0;
        shift_bit_r3           <= 0;
        float_exp_r3           <= 0;
        fixed_fraction_echo_r3 <= 0;
        fixed_integer_echo_r3  <= 0;
    end else if (clk_en) begin
        fixed_fraction_echo_r3  <= fixed_fraction_echo_r2;
        fixed_integer_echo_r3   <= fixed_integer_echo_r2;
        sign_r3                 <= sign_r2;
        mantissa_r3             <= mantissa_r3_comb;
        float_exp_r3            <= float_exp_r2 + {shift_bit_r2_comb, {NUM_SHIFT_REM_WID_2ND{1'd0}}};
        shift_bit_r3            <= shift_bit_r3_comb;
    end
end


always @(*) begin : stage_4_comb
    mantissa_r4_comb = ({mantissa_r3, {(MAX_SHIFT_RNG - ACC_SHIFT_RNG_2ND + NUM_PAD_BACK){sign_r3}} }) >> {shift_bit_r3};

    if (sign_r3) mantissa_r4_inv_comb = ~mantissa_r4_comb;
    else         mantissa_r4_inv_comb = mantissa_r4_comb;
end

always @(posedge clk or negedge rstn) begin : stage_4
    if (~rstn) begin
        sign_r4                <= 0;
        mantissa_r4_msb        <= 0;
        mantissa_r4_lsb        <= 0;
        float_exp_r4           <= 0;
        fixed_fraction_echo_r4 <= 0;
        fixed_integer_echo_r4  <= 0;
    end else if (clk_en) begin
        sign_r4                 <= sign_r3;
        fixed_fraction_echo_r4  <= fixed_fraction_echo_r3;
        fixed_integer_echo_r4   <= fixed_integer_echo_r3;
        float_exp_r4            <= float_exp_r3 + shift_bit_r3;

        /*  rounding, perform an addition in 2 cycles to improve the timing  */
        mantissa_r4_lsb <= {
        1'b0, 
        mantissa_r4_inv_comb[NUM_PAD_BACK + MAX_SHIFT_RNG-1 - MANT_WID + ADD_PARTIAL -: ADD_PARTIAL]
    } + mantissa_r4_inv_comb[NUM_PAD_BACK + MAX_SHIFT_RNG-1-MANT_WID] ;
        mantissa_r4_msb <= mantissa_r4_inv_comb[NUM_PAD_BACK + MAX_SHIFT_RNG-1 -: (MANT_WID - ADD_PARTIAL)];
    end
end


always @(*) begin : stage_5_comb
    mantissa_round_r5_comb = {
        {1'b0, mantissa_r4_msb} + mantissa_r4_lsb[ADD_PARTIAL], 
        mantissa_r4_lsb[0 +: ADD_PARTIAL]
    };
end

always @(posedge clk or negedge rstn) begin : stage_5
    if (~rstn) begin
        float_sign_r5 <= 0;
        float_exp_r5  <= 0;
        float_mant_r5 <= 0;
    end else if (clk_en) begin
        fixed_fraction_echo <= fixed_fraction_echo_r4;
        fixed_integer_echo  <= fixed_integer_echo_r4;
        float_sign_r5       <= sign_r4;
        float_exp_r5        <= float_exp_r4 + mantissa_round_r5_comb[MANT_WID];
        float_mant_r5       <= mantissa_round_r5_comb[0 +: MANT_WID];
    end
end

endmodule