module add_sub (
    input  wire [31:0] A, B,
    input  wire        clk,
    input  wire        reset,
    input  wire        stt,        // Start signal
    input  wire        op_add,     // 1 = add, 0 = subtract
    output reg  [31:0] result,
    output reg        result_valid
);
    reg caps, caps1, caps2, caps3, caps4; // Pipeline stage control signals
    wire [23:0] mantissax; // 24 bits for mantissa, 1 bit for carry
    wire [7:0] expx; // 8 bits for exponent
    // Stage 0: Input and comparison
    reg [31:0] A0, B0;
    reg        op_add0;
    wire       comp;

    // Stage 1: Unpack operands
    reg [23:0] A1_mantissa, B1_mantissa;
    reg [7:0]  A1_exp, B1_exp;
    reg        A1_sign, B1_sign;
    reg        op_add1;

    // Stage 2: Align and compute mantissa
    reg [23:0] B2_aligned, A2_mantissa;
    reg [7:0]  exp2;
    reg        op_add2;
    reg        A2_sign, B2_sign;
    reg [23:0] mantissa2;
    reg        carry2;

    // Stage 3: Normalize
    reg [23:0] mantissa3;
    reg [7:0]  exp3;
    reg        op_add3;
    reg        sign3;
    reg        sign5;
    reg        carry3;

    // Stage 4: Final sign
    reg [22:0] mantissa4;
    reg [7:0]  exp4;
    reg        sign4;

    // Stage 5: Final output formatting
    wire [31:0] result5;

    // Valid pipeline tracker
    reg [4:0] valid_pipe;
 

    // === Module: Comparator ===
    FloatingCompare comp_abs (
      .A(A[31:0]),
      .B(B[31:0]),
        .result(comp)
    );
    mantissa_normalizer norm (
        .mantissa_in(mantissa2),
        .exponent_in(exp2),
        .mantissa_out(mantissax),
        .exponent_out(expx)
    );
    // === Stage 0: Swap based on comparison ===
    always @(posedge clk) begin
        if (reset) begin
            A0 <= 0; B0 <= 0; op_add0 <= 0; caps <= 0;
            valid_pipe[0] <= 0;
        end else if (stt) begin
            A0 <= comp ? A : B;
            B0 <= comp ? B : A;
            op_add0 <= op_add;
            caps <= comp; // Reset caps
            valid_pipe[0] <= stt; 
        end else valid_pipe[0] <= 0; 
     end

    // === Stage 1: Unpack operands ===
    always @(posedge clk) begin
        valid_pipe[1] <= valid_pipe[0];
        
        if (valid_pipe[0] && (!reset) ) begin 
        A1_sign <= A0[31];
        B1_sign <= B0[31];
        A1_exp  <= A0[30:23];
        B1_exp  <= B0[30:23];
        A1_mantissa <= (A0[30:23] == 8'h00) ? {1'b0, A0[22:0]} : {1'b1, A0[22:0]};
        B1_mantissa <= (B0[30:23] == 8'h00) ? {1'b0, B0[22:0]} : {1'b1, B0[22:0]};
        op_add1 <= op_add0;
        caps1 <= caps; // Reset caps
         end else begin
            A1_sign <= 0;
            B1_sign <= 0;
            A1_exp <= 0;
            B1_exp <= 0;
            A1_mantissa <= 0;
            B1_mantissa <= 0;
            op_add1 <= 0;
            caps1 <= 0; // Reset caps 
       
        end
    end

    // === Stage 2: Align and compute ===
    always @(posedge clk) begin
        valid_pipe[2] <= valid_pipe[1];
        
        if (valid_pipe[1] && (!reset)) begin
            
            op_add2     <= op_add1;
            A2_sign     <= A1_sign;
            B2_sign     <= B1_sign;
            caps2 <= caps1; // Reset caps              
            if (A1_exp > B1_exp) begin
              if (op_add1) begin
                  {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                  (A1_mantissa +  (B1_mantissa >> (A1_exp - B1_exp))) :
                  (A1_mantissa -  (B1_mantissa >> (A1_exp - B1_exp)));
              end else begin
                  {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                  (A1_mantissa -  (B1_mantissa >> (A1_exp - B1_exp))) :
                  (A1_mantissa +  (B1_mantissa >> (A1_exp - B1_exp)));
              end
              exp2        <= A1_exp;
            end else if (A1_exp == B1_exp) begin
                if (op_add1) begin
                  {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                  (A1_mantissa +  (B1_mantissa)) :
                  (A1_mantissa -  (B1_mantissa));
                end else begin
                  {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                  (A1_mantissa -  (B1_mantissa )) :
                  (A1_mantissa +  (B1_mantissa ));
                end
                exp2        <= A1_exp;
            end else begin
               if (op_add1) begin
                  {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                  (A1_mantissa +  (B1_mantissa >> (A1_exp - B1_exp))) :
                  (A1_mantissa -  (B1_mantissa >> (A1_exp - B1_exp)));
                end else begin
                    {carry2, mantissa2} <= (A1_sign ~^ B1_sign) ?
                    (B1_mantissa -  (A1_mantissa >> (B1_exp - A1_exp))) :
                    (B1_mantissa +  (A1_mantissa >> (B1_exp - A1_exp)));
                    exp2        <= B1_exp;
              end
            end
         
        end else begin
            exp2 <= 0;
            op_add2 <= 0;
            A2_sign <= 0;
            B2_sign <= 0;
            mantissa2 <= 0;
            carry2 <= 0;
            caps2 <= 0; // Reset caps
        end   
    end

    // === Stage 3: Normalize ===
    integer i;
    always @(posedge clk) begin
        valid_pipe[3] <= valid_pipe[2];
        if (valid_pipe[2] && (!reset)) begin
            sign3 <= A2_sign;
            op_add3 <= op_add2;
            sign5 <= B2_sign; // Default to A's sign
            caps3 <= caps2; // Reset caps
            carry3 <= carry2;
            if (carry2) begin
                mantissa3 <= mantissa2 >> 1;
                exp3 <= (exp2 < 8'hFF) ? exp2 + 1 : 8'hFF;
            end else begin
                mantissa3 <= mantissax;
                exp3 <= expx;
            end
        end else begin
            sign3 <= 0;
            op_add3 <= 0;
            mantissa3 <= 0;
            exp3 <= 0;
            caps3 <= 0; // Reset caps
            carry3 <= 0;
        end	
    end

    // === Stage 4: Final sign and mantissa cut ===
    always @(posedge clk) begin
        valid_pipe[4] <= valid_pipe[3];
        if (valid_pipe[3] && (!reset)) begin
            caps4 <= caps3; // Reset caps
            if (mantissa3 == 0 && carry3 == 0)begin
                exp4 <= 8'h00; // Zero case
                mantissa4 <= 23'b0; // Zero mantissa
                sign4 <= 1'b0; // Zero sign
            end else if (exp3 == 8'hff) begin 
                exp4 <= 8'h00; // inif case
                mantissa4 <= 23'b0; 
                sign4 <= 1'b0; 
            end else begin
                exp4 <= exp3;
                mantissa4 <= mantissa3[22:0];
   // Final sign logic
                if (!op_add3) begin
                   
                    if ((!sign3) && (sign5)) begin
                       if (caps3) sign4 <= 1'b0;
                       else sign4 <= 1'b1;
                    end else if ((sign3) && (!sign5)) begin
                        if (caps3) sign4 <= 1'b1;
                       else sign4 <= 1'b0;
                    end else if ((!sign3) &&(!sign5)) begin
                        if(!caps3) sign4 <= 1'b1;
                        else sign4 <= 1'b0;
                    end else if ((sign3) && (sign5)) begin
                        if(!caps3)sign4 <= 1'b0;
                        else sign4 <= 1'b1;
                    end 
                end else begin
                    sign4 <= sign3;
                end
            end
        end else begin
            exp4 <= 0;
            mantissa4 <= 0;
            sign4 <= 0;
            caps4 <= 0; // Reset caps
        end
    end 
    // === Stage 5: Final result ===
    always @(posedge clk) begin
        if (valid_pipe[4] && (!reset)) begin
            result <= {sign4, exp4, mantissa4}; // Reset result on valid pipe
            result_valid <= 1'b1; // Set result valid
            $strobe("result:%h",result);
        end else begin
            result_valid <= 1'b0; // Reset result valid
            result <= 32'b0; // Reset result if not valid
        end
    end
endmodule

module FloatingCompare (
    input  [31:0] A,
    input  [31:0] B,
    output reg    result
);
    always @(*) begin
        // compare exponents
        
            if (A[30:23] != B[30:23]) begin
                result = (A[30:23] > B[30:23]) ? 1'b1 : 1'b0;  
            end
            // compare mantissas
            else begin
                if(A[22:0] != B[22:0])begin
                    result = (A[22:0] > B[22:0]) ? 1'b1 : 1'b0;  
                end else begin 
                    result = 1'b1;
                end
            end 
        
    end
endmodule

module mantissa_normalizer (
    input  wire [23:0] mantissa_in,     // Unnormalized mantissa
    input  wire [7:0]  exponent_in,     // Input exponent
    output wire [23:0] mantissa_out,    // Normalized mantissa
    output wire [7:0]  exponent_out     // Adjusted exponent
);

    // Leading-zero count function
    function [4:0] count_leading_zeros;
        input [23:0] in;
        begin
            casex (in)
                24'b1xxxxxxxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd0;
                24'b01xxxxxxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd1;
                24'b001xxxxxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd2;
                24'b0001xxxxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd3;
                24'b00001xxxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd4;
                24'b000001xxxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd5;
                24'b0000001xxxxxxxxxxxxxxxxx: count_leading_zeros = 5'd6;
                24'b00000001xxxxxxxxxxxxxxxx: count_leading_zeros = 5'd7;
                24'b000000001xxxxxxxxxxxxxxx: count_leading_zeros = 5'd8;
                24'b0000000001xxxxxxxxxxxxxx: count_leading_zeros = 5'd9;
                24'b00000000001xxxxxxxxxxxxx: count_leading_zeros = 5'd10;
                24'b000000000001xxxxxxxxxxxx: count_leading_zeros = 5'd11;
                24'b0000000000001xxxxxxxxxxx: count_leading_zeros = 5'd12;
                24'b00000000000001xxxxxxxxxx: count_leading_zeros = 5'd13;
                24'b000000000000001xxxxxxxxx: count_leading_zeros = 5'd14;
                24'b0000000000000001xxxxxxxx: count_leading_zeros = 5'd15;
                24'b00000000000000001xxxxxxx: count_leading_zeros = 5'd16;
                24'b000000000000000001xxxxxx: count_leading_zeros = 5'd17;
                24'b0000000000000000001xxxxx: count_leading_zeros = 5'd18;
                24'b00000000000000000001xxxx: count_leading_zeros = 5'd19;
                24'b000000000000000000001xxx: count_leading_zeros = 5'd20;
                24'b0000000000000000000001xx: count_leading_zeros = 5'd21;
                24'b00000000000000000000001x: count_leading_zeros = 5'd22;
                24'b000000000000000000000001: count_leading_zeros = 5'd23;
                default: count_leading_zeros = 5'd24; // All zeros
            endcase
        end
    endfunction

    wire [4:0] shift_amount = count_leading_zeros(mantissa_in);

    // Shift and adjust
    assign mantissa_out  = mantissa_in << shift_amount;
    assign exponent_out  = exponent_in - shift_amount;

endmodule
