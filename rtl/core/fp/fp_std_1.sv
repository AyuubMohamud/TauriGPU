module fp_std_1 #(
    parameter WIDTH = 24
)(
    input wire [WIDTH - 1:0] a,
    input wire [3:0]  opcode,
    output logic [WIDTH - 1:0] result
);

    // Extract fields from input
    logic max_sign = a[23];
    logic [7:0] max_exponent = a[22:15];
    logic [15:0] add_result_mantissa = a[14:0];
    logic [15:0] sub_result_mantissa = a[30:15];

    logic [7:0] new_exp_diff;
    wire [4:0] new_exp_diff_w = new_exp_diff[3:0] + 1;

    wire [7:0] add_result_exponent = add_result_mantissa[15] ? max_exponent + 1 : max_exponent;
    logic [15:0] new_sub_result_mantissa;
    logic [7:0] sub_result_exponent;

    always_comb begin
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
        sub_result_exponent = max_exponent - new_exp_diff;

        case(opcode[1:0])
            2'b00: result = {max_sign, add_result_exponent, add_result_mantissa[15] ? add_result_mantissa[14:0] : add_result_mantissa[13:0]};
            2'b01: result = {max_sign, sub_result_exponent, new_sub_result_mantissa[15:1]};
            default: result = 24'b0;
        endcase
    end

endmodule