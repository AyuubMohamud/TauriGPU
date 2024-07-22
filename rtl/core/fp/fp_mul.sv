module fp_mul #(
    parameter WIDTH = 24
)(
    input logic clk, 
    input wire [WIDTH - 1:0] a,
    input wire [WIDTH - 1:0] b,

    output wire [23:0] result
);

    logic [16:0] product_o;
    logic zero_flag_o;
    logic sign_xor_o;
    logic [8:0] sum_exp_o;

    fp_mul_0 fp_mul_0_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .product_o(product_o),
        .zero_flag_o(zero_flag_o),
        .sign_xor_o(sign_xor_o),
        .sum_exp_o(sum_exp_o)
    );

    fp_mul_1 fp_mul_1_inst (
        .clk(clk),
        .product_i(product_o),
        .zero_flag_i(zero_flag_o),
        .sign_xor_i(sign_xor_o),
        .sum_exp_i(sum_exp_o),
        .result_o(result)
    );

endmodule
