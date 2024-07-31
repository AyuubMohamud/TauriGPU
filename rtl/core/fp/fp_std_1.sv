module fp_std_1 #(
    parameter WIDTH = 24
)(
    input logic clk_i,
    input wire [3:0] op_i,

    input logic [WIDTH - 1:0] result_i,
    input logic [16:0] add_result_mantissa_i,
    input logic [15:0] sub_result_mantissa_i,
    input logic max_sign_i,
    input logic min_sign_i,
    input logic [WIDTH - 1:0] max_result_i,
    input logic [WIDTH - 1:0] min_result_i,
    input logic [7:0] max_exponent_i,

    output logic [WIDTH - 1:0] result_o
);

    logic [WIDTH - 1:0] add_sub_result;
    logic [7:0] new_exp_diff;
    wire [4:0] new_exp_diff_w;
    wire [7:0] add_result_exponent;
    wire [15:0] new_sub_result_mantissa;
    wire [7:0] sub_result_exponent;

    assign new_exp_diff_w = new_exp_diff[3:0] + 1;

    assign add_result_exponent = add_result_mantissa_i[16] ? max_exponent_i + 1 : max_exponent_i;
    assign new_sub_result_mantissa = sub_result_mantissa_i << new_exp_diff_w;
    assign sub_result_exponent = max_exponent_i - new_exp_diff;

    // Determine new_exp_diff
    always_comb begin
        casez (sub_result_mantissa_i)
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
            default: new_exp_diff = max_exponent_i;
        endcase
    end

    // Registered output
    logic [WIDTH - 1:0] result_reg;

    always_ff @(posedge clk_i) begin
        // Register the final result
        case (op_i[1:0])
            2'b00: result_reg <= max_sign_i == min_sign_i ? {max_sign_i, add_result_exponent, add_result_mantissa_i[16] ? add_result_mantissa_i[15:1] : add_result_mantissa_i[14:0]} : {max_sign_i, sub_result_exponent, new_sub_result_mantissa[15:1]};
            2'b01: result_reg <= max_result_i;
            2'b10: result_reg <= min_result_i;
            default: result_reg <= 24'b0;
        endcase
    end

    assign result_o = result_reg;

endmodule
