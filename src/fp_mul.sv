module fp_mul #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH - 1:0] a,
    input  wire [WIDTH - 1:0] b,
    output wire [WIDTH - 1:0] result
);
    // Extract fields from input
    logic sign1 = a[23];
    logic sign2 = b[23];
    logic [7:0] exp1 = a[22:15];
    logic [7:0] exp2 = b[22:15];
    // exp1 == 0 ? 
    logic mantissa_top_bit_1 = exp1==0 ? 1'b0 : 1'b1;
    logic mantissa_top_bit_2 = exp2==0 ? 1'b0 : 1'b1;
    logic [15:0] mant1 = {mantissa_top_bit_1, a[14:0]}; // implicit leading 1
    logic [15:0] mant2 = {mantissa_top_bit_2, b[14:0]}; 

    logic sign_o;
    logic [7:0] exp_o;
    logic [14:0] mant_o;
    logic [31:0] product = mant1 * mant2; // 16-bit mantissa * 16-bit mantissa = 32-bit product
    always_comb begin
        // If either input number has a high-order bit of zero, then that input is zero and the product is zero.
        if (mant1[15] == 0 || mant2[15] == 0) begin
            sign_o = 0;
            exp_o = 0;
            mant_o = 0;
        end
        /*
            The output exponent is exp1+exp2-126 or exp1+exp2-127. 
            If the sums of the input exponents is less than 128, 
            then the exponent will underflow and the product is zero.
        */
        else if (exp1 + exp2 < 128) begin
            sign_o = 0;
            exp_o = 0;
            mant_o = 0;
        end
        // If both inputs are nonzero and the exponents don't underflow
        else begin
            // Then if (mantissa1)x(mantissa2) has the high order-bit set, the top 9-bits of the product are the output mantissa and the output exponent is exp1+exp2-128.
            if (product[31] == 1) begin // NOT SURE OF THIS LINE
                exp_o = exp1 + exp2 - 126;
                mant_o = product[30:16]; // top 23 bits of product
            end

            // Otherwise the second bit of the product will be set, and the output mantissa is the top 9-bits of (product)<<1 and the output exponent is exp1+exp2-129.
            else begin
                exp_o = exp1 + exp2 - 127;
                mant_o = product[29:15]; // top 23 bits of product shifted left by 1
            end

            // The sign of the product is (sign1)xor(sign2)
            sign_o = sign1 ^ sign2;
        end
    end

    assign result = {sign_o, exp_o, mant_o};
    
endmodule
