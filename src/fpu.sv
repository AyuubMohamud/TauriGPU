module fpu #(
    parameter ADDR_WIDTH = 32, 
              DATA_WIDTH = 32,
              WIDTH = 32
)(
    input   wire logic [WIDTH - 1:0] a,
    input   wire logic [WIDTH - 1:0] b,
    input   wire logic [2:0]         FPUctrl,
    output  wire logic [WIDTH - 1:0] FPUout
);

    logic [WIDTH - 1:0] result_std;
    logic [WIDTH - 1:0] result_mul;
    logic [WIDTH - 1:0] result_abs;
    logic [WIDTH - 1:0] result_neg;

    // Floating-point standard operations (addition, subtraction, max, min)
    fp_std fp_std_inst (
        .a(a),
        .b(b),
        .op(FPUctrl[2:0]),
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

    always_comb begin
        case(FPUctrl)
            3'b000, 3'b001, 3'b011, 3'b100: result = result_std;
            3'b010: result = result_mul; 
            3'b101: result = result_abs;
            3'b110: result = result_neg;
            default: result = 0;     
        endcase
    end

    assign FPUout = result;

endmodule
