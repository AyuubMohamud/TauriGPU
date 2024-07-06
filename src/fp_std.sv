module fp_std #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH - 1:0] a,
    input  wire [WIDTH - 1:0] b,
    input  wire [2:0]  op,
    output wire [WIDTH - 1:0] result
);

    logic [31:0] add_result;
    logic [31:0] sub_result;
    logic [31:0] max_result;
    logic [31:0] min_result;

    // Extract fields from input
    logic sign1 = a[23];
    logic sign2 = b[23];
    logic [7:0] exp1 = a[22:15];
    logic [7:0] exp2 = b[22:15];

    // Floating-point addition
    // For point 3, make the comparison greater than 15 instead of 8

    // 1. If both inputs are zero, the sum is zero
    
    if (exp1 == 0 && exp2 == 0) begin
        add_result = 32'b0;
    end

    // 2. Determine which input is bigger, which smaller (absolute value) by first comparing the exponents, then the mantissas if necessary.



    // 3. Determine the difference in the exponents and shift the smaller input mantissa right by the difference. 
    // But if the exponent difference is greater than 8 then just output the bigger input.


    // 4. If the signs of the inputs are the same, add the bigger and (shifted) smaller mantissas. The result must be 0.5<sum<2.0. If the result is greater than one, shift the mantissa sum right one bit and increment the exponent. The sign is the sign of either input.


    // 5. If the signs of the inputs are different, subtract the bigger and (shifted) smaller mantissas so that the result is always positive. The result must be 0.0<difference<0.5. Shift the mantissa left until the high bit is set, while decrementing the exponent. The sign is the sign of the bigger input.


    always_comb begin
        case(op)
            3'b000: result = add_result;
            3'b001: result = sub_result;
            3'b011: result = max_result;
            3'b100: result = min_result;
            default: result = 32'b0;     
        endcase
    end

endmodule
