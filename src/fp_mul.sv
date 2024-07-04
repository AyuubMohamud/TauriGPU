module fp_mul (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result
);

    // Extract fields from input
    logic sign1 = a[31]
    logic sign2 = b[31]
    logic [7:0] exp1 = a[30:23]
    logic [7:0] exp2 = b[30:23]
    logic [22:0] mant1 = {1'b1, a[22:0]}; // implicit leading 1
    logic [22:0] mant2 = {1'b1, b[22:0]}; 

    logic sign_o;
    logic [7:0] exp_o;
    logic [22:0] mant_o;
    logic [47:0] product; // 24-bit mantissa * 24-bit mantissa = 48-bit product

    always_comb begin
        // If either input number has a high-order bit of zero, then that input is zero and the product is zero.
        if (mant1[22] == 0 || mant2[22] == 0) begin
            sign_o = 0;
            exp_o = 0;
            mant_o = 0;
        end
        /*
            The output exponent is exp1+exp2-128 or exp1+exp2-129. 
            If the sums of the input exponents is less than 129, 
            then the exponent will underflow and the product is zero.
        */
        else if (exp1 + exp2 < 128) begin
            sign_o = 0;
            exp_o = 0;
            mant_o = 0;
        end
        // If both inputs are nonzero and the exponents don't underflow
        else begin
            product = mant1 * mant2;
            
            // Then if (mantissa1)x(mantissa2) has the high order-bit set, the top 9-bits of the product are the output mantissa and the output exponent is exp1+exp2-128.
            if (product[47] == 1) begin // NOT SURE OF THIS LINE
                exp_o = exp1 + exp2 - 127;
                mant_o = product[46:24]; // top 23 bits of product
            end

            // Otherwise the second bit of the product will be set, and the output mantissa is the top 9-bits of (product)<<1 and the output exponent is exp1+exp2-129.
            else begin
                exp_o = exp1 + exp2 - 128;
                mant_o = product[45:23]; // top 23 bits of product shifted left by 1
            end

            // The sign of the product is (sign1)xor(sign2)
            sign_o = sign1 ^ sign2;
        end
    end

    assign result = {sign_o, exp_o, mant_o};
    
endmodule
