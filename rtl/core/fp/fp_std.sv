module fp_std #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH - 1:0] a,
    input  wire [WIDTH - 1:0] b,
    input  wire [3:0]  op,
    output logic [WIDTH - 1:0] result
);

    logic [WIDTH - 1:0] add_sub_result;
    logic [WIDTH - 1:0] max_result;
    logic [WIDTH - 1:0] min_result;

    // Extract fields from input
    logic sign1 = a[23];
    logic sign2 = op[2] == 1 ? ~b[23] : b[23];
    logic [7:0] exp1 = a[22:15];
    logic [7:0] exp2 = b[22:15];

    logic [7:0] new_exp_diff;
    wire [4:0] new_exp_diff_w = new_exp_diff[3:0] + 1;

    logic mantissa_top_bit_1 = exp1==0 ? 1'b0 : 1'b1;
    logic mantissa_top_bit_2 = exp2==0 ? 1'b0 : 1'b1;
    logic [15:0] mant1 = {mantissa_top_bit_1, a[14:0]}; // implicit leading 1
    logic [15:0] mant2 = {mantissa_top_bit_2, b[14:0]}; 

    wire a_is_bigger = exp1 > exp2 || (exp1 == exp2 && mant1 > mant2);

    wire [15:0] max_mantissa = a_is_bigger ? mant1 : mant2;
    wire [7:0] max_exponent = a_is_bigger ? exp1 : exp2;
    wire [15:0] min_mantissa = a_is_bigger ? mant2 : mant1;
    wire [7:0] min_exponent = a_is_bigger ? exp2 : exp1;
    wire [7:0] exp_diff = max_exponent - min_exponent;

    wire [15:0] shift_mantissa = min_mantissa >> exp_diff[3:0];

    wire [16:0] add_result_mantissa = max_mantissa + shift_mantissa;
    wire [15:0] sub_result_mantissa = max_mantissa - shift_mantissa;
    logic [15:0] new_sub_result_mantissa;

    wire [7:0] add_result_exponent = add_result_mantissa[16] ? max_exponent + 1 : max_exponent;
    wire [7:0] sub_result_exponent = max_exponent - new_exp_diff;

    wire max_sign = a_is_bigger ? sign1 : sign2;

    always_comb begin

        max_result = 24'b0;
        min_result = 24'b0;

        // 1. If both inputs are zero, the sum is zero

        // 2. Determine which input is bigger, which smaller (absolute value) by first comparing the exponents, then the mantissas if necessary.

        if (!sign1 && !sign2) begin
            max_result = a_is_bigger ? a : b;
            min_result = a_is_bigger ? b : a;
        end else if (!sign1&&sign2) begin
            max_result = a;
            min_result = b;
        end else if (sign1&!sign2) begin
            max_result = b;
            min_result = a;
        end else if (sign1&sign2) begin
            max_result = a_is_bigger ? b : a;
            min_result = a_is_bigger ? a : b;
        end
        
        // 3. Determine the difference in the exponents and shift the smaller input mantissa right by the difference. 
        // But if the exponent difference is greater than 15 then just output the bigger input.

        // 4. If the signs of the inputs are the same, add the bigger and (shifted) smaller mantissas. 
        // The result must be 0.5<sum<2.0. If the result is greater than one, shift the mantissa sum right one bit and increment the exponent. 
        // The sign is the sign of either input.

        // 5. If the signs of the inputs are different, subtract the bigger and (shifted) smaller mantissas so that the result is always positive. 
        // The result must be 0.0<difference<0.5. 
        // Shift the mantissa left until the high bit is set, while decrementing the exponent. 
        // The sign is the sign of the bigger input.

        casez (sub_result_mantissa)
            16'b1???????????????: new_exp_diff = 0;
            16'b01??????????????: new_exp_diff = 1;
            16'b001?????????????: new_exp_diff = 2;
            16'b0001????????????: new_exp_diff = 3;
            16'b00001???????????: new_exp_diff = 4;
            16'b000001??????????: new_exp_diff = 5;
            16'b0000001?????????: new_exp_diff = 6;
            16'b00000001????????: new_exp_diff = 7;
            16'b000000001???????: new_exp_diff = 8;
            16'b0000000001??????: new_exp_diff = 9;
            16'b00000000001?????: new_exp_diff = 10;
            16'b000000000001????: new_exp_diff = 11;
            16'b0000000000001???: new_exp_diff = 12;
            16'b00000000000001??: new_exp_diff = 13;
            16'b000000000000001?: new_exp_diff = 14;
            16'b0000000000000001: new_exp_diff = 15;
            default: new_exp_diff = 0;
        endcase

        new_sub_result_mantissa = sub_result_mantissa << new_exp_diff_w;

        if (exp_diff > 15) begin
            add_sub_result = a_is_bigger ? a : b;
        end else begin
            add_sub_result = (sign1 == sign2) ? {sign1, add_result_exponent, add_result_mantissa[16] ? add_result_mantissa[15:1] : add_result_mantissa[14:0]} : {max_sign, sub_result_exponent, new_sub_result_mantissa[15:1]};
        end

        case(op[1:0])
            2'b00: result = exp1 == 0 && exp2 == 0 ? 24'b0 : add_sub_result;
            2'b01: result = max_result;
            2'b10: result = min_result;
            default: result = 24'b0;
        endcase

    end

endmodule
