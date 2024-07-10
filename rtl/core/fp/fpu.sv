module fpu #(
    parameter WIDTH = 24
)(
    input   logic clk,
    input   wire logic [WIDTH - 1:0] a,
    input   wire logic [WIDTH - 1:0] b,
    input   wire logic [3:0]         opcode,

    output  wire logic [WIDTH - 1:0] result
);

    logic [WIDTH - 1:0] result_std;
    logic [WIDTH - 1:0] result_mul;
    logic [WIDTH - 1:0] result_abs;
    logic [WIDTH - 1:0] result_neg;
    logic [WIDTH - 1:0] result_floor;
    logic [WIDTH - 1:0] result_ceil;
    logic [WIDTH - 1:0] result_sign;

    /* FP pipelines
        1. Add line: Std, Floor, Ceil  
        2. Mul line: Mul
        3. Misc line: Abs, Neg, Sign
    */

    // Floating-point standard operations (addition, subtraction, max, min)
    fp_std fp_std_inst (
        .a(a),
        .b(b),
        .op(opcode[3:0]),
        .result(result_std)
    );

    fp_mul fp_mul_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .result(result_mul)
    );

    fp_abs fp_abs_inst (
        .a(a),
        .result(result_abs)
    );

    fp_neg fp_neg_inst (
        .a(a),
        .result(result_neg)
    );

    fp_floor fp_floor_inst (
        .a(a),
        .result(result_floor)
    );

    fp_ceil fp_ceil_inst (
        .a(a),
        .result(result_ceil)
    );

    fp_sign fp_sign_inst (
        .a(a),
        .result(result_sign)
    );

    always_comb begin
        case(opcode)
            4'b0000, 4'b0100, 4'b0001, 4'b0010: result = result_std;
            4'b0011: result = result_mul;
            4'b0101: result = result_abs;
            4'b0110: result = result_neg;
            4'b1000: result = result_floor;
            4'b1001: result = result_ceil;
            4'b1010: result = result_sign;
            default: result = 0;     
        endcase
    end

endmodule
