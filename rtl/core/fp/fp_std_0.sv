module fp_std_0 #(
    parameter WIDTH = 24
)(
    input  logic clk_i,
    input  wire [WIDTH - 1:0] a_i,
    input  wire [WIDTH - 1:0] b_i,
    input  wire [3:0]  op_i,

    output logic [WIDTH - 1:0] result_o,
    output logic [16:0] add_result_mantissa_o,
    output logic [15:0] sub_result_mantissa_o,
    output logic max_sign_o,
    output logic min_sign_o,
    output logic [WIDTH - 1:0] max_result_o,
    output logic [WIDTH - 1:0] min_result_o,
    output logic [7:0] max_exponent_o
);

    logic [WIDTH - 1:0] max_result;
    logic [WIDTH - 1:0] min_result;

    // Extract fields from input
    logic sign1 = a_i[23];
    logic sign2 = op_i[2] == 1 ? ~b_i[23] : b_i[23];
    logic [7:0] exp1 = a_i[22:15];
    logic [7:0] exp2 = b_i[22:15];

    logic mantissa_top_bit_1 = exp1==0 ? 1'b0 : 1'b1;
    logic mantissa_top_bit_2 = exp2==0 ? 1'b0 : 1'b1;
    logic [15:0] mant1 = {mantissa_top_bit_1, a_i[14:0]}; // implicit leading 1
    logic [15:0] mant2 = {mantissa_top_bit_2, b_i[14:0]}; 

    wire a_is_bigger = exp1 > exp2 || (exp1 == exp2 && mant1 > mant2);

    wire [15:0] max_mantissa = a_is_bigger ? mant1 : mant2;
    wire [7:0] max_exponent = a_is_bigger ? exp1 : exp2;
    wire [15:0] min_mantissa = a_is_bigger ? mant2 : mant1;
    wire [7:0] min_exponent = a_is_bigger ? exp2 : exp1;

    wire [7:0] exp_diff = max_exponent - min_exponent;

    wire [15:0] shift_mantissa = min_mantissa >> exp_diff[3:0];

    wire [16:0] add_result_mantissa = max_mantissa + shift_mantissa;
    wire [15:0] sub_result_mantissa = max_mantissa - shift_mantissa;

    wire max_sign = a_is_bigger ? sign1 : sign2;
    wire min_sign = a_is_bigger ? sign2 : sign1;

    always_comb begin

        max_result = 24'b0;
        min_result = 24'b0;

        // 1. If both inputs are zero, the sum is zero

        // 2. Determine which input is bigger, which smaller (absolute value) by first comparing the exponents, then the mantissas if necessary.

        if (!sign1 && !sign2) begin
            max_result = a_is_bigger ? a_i : b_i;
            min_result = a_is_bigger ? b_i : a_i;
        end else if (!sign1&&sign2) begin
            max_result = a_i;
            min_result = b_i;
        end else if (sign1&!sign2) begin
            max_result = b_i;
            min_result = a_i;
        end else if (sign1&sign2) begin
            max_result = a_is_bigger ? b_i : a_i;
            min_result = a_is_bigger ? a_i : b_i;
        end

    end

    always_ff @(posedge clk_i) begin
        
        max_result_o <= max_result;
        min_result_o <= min_result;
        add_result_mantissa_o <= add_result_mantissa;
        sub_result_mantissa_o <= sub_result_mantissa;
        max_sign_o <= max_sign;
        min_sign_o <= min_sign;
        max_exponent_o <= max_exponent;

    end

endmodule
