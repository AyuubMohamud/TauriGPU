module fpu #(
    parameter WIDTH = 24
)(
    input   wire logic [WIDTH - 1:0] a,
    input   wire logic [WIDTH - 1:0] b,
    input   wire logic [3:0]         FPUctrl,
    output  wire logic [WIDTH - 1:0] FPUout
);

    logic [WIDTH - 1:0] result_std;
    logic [WIDTH - 1:0] result_mul;
    logic [WIDTH - 1:0] result_abs;
    logic [WIDTH - 1:0] result_neg;
    logic [WIDTH - 1:0] result_floor;
    logic [WIDTH - 1:0] result_ceil;
    logic [WIDTH - 1:0] result_sign;
    logic [WIDTH - 1:0] result;

    // Floating-point standard operations (addition, subtraction, max, min)
    fp_std fp_std_inst (
        .a(a),
        .b(b),
        .op(FPUctrl[3:0]),
        .result(result_std)
    );

    fp_mul fp_mul_inst (
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

    /*
    Notes:
    - No need rounding, we're not doing a fully IEEE 754 compliant implementation
    - Need to:
        - Store implicit 1
        - Complete fp_std
        - Implement fp_mul
        - Just cut out the last 8 bits for everything
    */

    always_comb begin
        case(FPUctrl)
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

    assign FPUout = result;

endmodule
