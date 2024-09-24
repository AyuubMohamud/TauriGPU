module fpu #(
    parameter WIDTH = 24
)(
    input   logic clk,
    input   wire logic [WIDTH - 1:0] a,
    input   wire logic [WIDTH - 1:0] b,
    input   wire logic [3:0]         opcode,

    output  logic [WIDTH - 1:0] result
);

    logic [WIDTH - 1:0] result_std;
    logic [WIDTH - 1:0] result_mul;
    logic [WIDTH - 1:0] result_misc;


    /* FP pipelines
        1. Add line: Std (add, sub, max, min), Floor, Ceil  
        2. Mul line: Mul
        3. Misc line: Abs, Neg, Sign
    */

    fp_addpipe fp_addpipe_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .opcode(opcode),
        .result(result_std)
    );

    fp_mul fp_mul_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .result(result_mul)
    );

    fp_misc fp_misc_inst (
        .clk(clk),
        .a(a),
        .opcode(opcode),
        .result(result_misc)
    );

    always_comb begin
        case(opcode)
            4'b0000, 4'b0100, 4'b0001, 4'b0010: result = result_std;
            4'b0011: result = result_mul;
            default: result = result_misc;     
        endcase
    end

endmodule
