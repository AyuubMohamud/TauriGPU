module fp_misc #(
    parameter WIDTH = 24
)(
    input logic clk,
    input logic [WIDTH - 1:0] a,
    input logic [3:0] opcode,

    output logic [WIDTH - 1:0] result
);

    wire [WIDTH - 1:0] result_neg; // 0110
    wire [WIDTH - 1:0] result_abs; // 0101
    wire [WIDTH - 1:0] result_sign; // 1010

    wire [WIDTH - 1:0] intermmediate_result;
    reg [WIDTH - 1:0] intermmediate_result_reg;

    fp_neg #(.WIDTH(WIDTH)) fp_neg_inst (
        .a(a),
        .result(result_neg)
    );

    fp_abs #(.WIDTH(WIDTH)) fp_abs_inst (
        .a(a),
        .result(result_abs)
    );

    fp_sign #(.WIDTH(WIDTH)) fp_sign_inst (
        .a(a),
        .result(result_sign)
    );

    assign intermmediate_result = (opcode == 4'b0110) ? result_neg :
                    (opcode == 4'b0101) ? result_abs :
                    result_sign;
                    
    always_ff @(posedge clk) begin
        intermmediate_result_reg <= intermmediate_result;
        result <= intermmediate_result_reg;
    end

endmodule
