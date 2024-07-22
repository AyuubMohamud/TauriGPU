module fp_mul_1 #(
    parameter WIDTH = 24
)(
    input  logic            clk,
    input  wire [16:0]      product_i,
    input  wire             zero_flag_i,
    input  logic            sign_xor_i,
    input  wire [8:0]       sum_exp_i,
    
    output logic [WIDTH - 1:0] result_o
);

    logic sign_o;
    logic [8:0] exp_o;
    logic [14:0] mant_o;

    always_ff @(posedge clk) begin
        // If both inputs are nonzero and the exponents don't underflow        
        if (!zero_flag_i) begin
            // Then if (mantissa1)x(mantissa2) has the high order-bit set, the top 9-bits of the product are the output mantissa and the output exponent is exp1+exp2-128.
            if (product_i[16] == 1) begin
                exp_o <= sum_exp_i - 126;
                mant_o <= product_i[15:1]; // top 23 bits of product
            end

            // Otherwise the second bit of the product will be set, and the output mantissa is the top 9-bits of (product)<<1 and the output exponent is exp1+exp2-129.
            else begin
                exp_o <= sum_exp_i - 127;
                mant_o <= product_i[14:0]; // top 23 bits of product shifted left by 1
            end

            // The sign of the product is (sign1)xor(sign2)
            sign_o <= sign_xor_i;

        end else begin
            // If either input number has a high-order bit of zero, then that input is zero and the product is zero.
            sign_o <= 0;
            exp_o <= 0;
            mant_o <= 0;
        end

    end

    assign result_o = exp_o > 254 ? 24'h7f8000 : {sign_o, exp_o[7:0], mant_o};
    
endmodule
