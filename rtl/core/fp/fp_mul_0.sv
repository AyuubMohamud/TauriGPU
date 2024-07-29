module fp_mul_0 #(
    parameter WIDTH = 24
)(
    input logic clk,

    input  wire [WIDTH - 1:0] a,
    input  wire [WIDTH - 1:0] b,

    output logic [16:0] product_o,
    output logic zero_flag_o,
    output logic sign_xor_o,
    output logic [8:0] sum_exp_o
);
    // Extract fields from input
    logic sign1;
    logic sign2;

    logic [7:0] exp1;
    logic [7:0] exp2;

    logic mantissa_top_bit_1;
    logic mantissa_top_bit_2;

    logic [15:0] mant1;
    logic [15:0] mant2;

    logic [31:0] product;

    // Assign values to the fields
    assign sign1 = a[23];
    assign sign2 = b[23];

    assign exp1 = a[22:15];
    assign exp2 = b[22:15];

    assign mantissa_top_bit_1 = (exp1 == 0) ? 1'b0 : 1'b1;
    assign mantissa_top_bit_2 = (exp2 == 0) ? 1'b0 : 1'b1;

    assign mant1 = {mantissa_top_bit_1, a[14:0]}; // implicit leading 1
    assign mant2 = {mantissa_top_bit_2, b[14:0]}; 

    assign product = mant1 * mant2; // 16-bit mantissa * 16-bit mantissa = 32-bit product

    always_ff @(posedge clk) begin
        // If either input number has a high-order bit of zero, then that input is zero and the product is zero.
        if (mant1[15] == 0 || mant2[15] == 0) begin
            zero_flag_o <= 1;
        end
        /*
            The output exponent is exp1+exp2-126 or exp1+exp2-127. 
            If the sums of the input exponents is less than 128, 
            then the exponent will underflow and the product is zero.
        */
        else if (exp1 + exp2 < 128) begin
            zero_flag_o <= 1;
        end else begin
            zero_flag_o <= 0;
        end

        product_o <= product[31:15]; // top 17 bits of product

        sign_xor_o <= sign1 ^ sign2;
        sum_exp_o <= exp1 + exp2;

    end
    
endmodule
