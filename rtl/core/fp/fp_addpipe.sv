module fp_addpipe #(
    parameter WIDTH = 24
)(
    input logic clk,
    input logic [WIDTH - 1:0] a,
    input logic [WIDTH - 1:0] b,
    input logic [3:0] opcode,

    output logic [WIDTH - 1:0] result
);

    wire [WIDTH - 1:0] std_result_stage1;
    wire [WIDTH - 1:0] std_result_stage2;
    wire [WIDTH - 1:0] floor_result;
    wire [WIDTH - 1:0] ceil_result;

    reg [WIDTH - 1:0] a_reg, b_reg;
    reg [3:0] opcode_reg;
    reg [WIDTH - 1:0] std_result_stage1_reg;
    reg [WIDTH - 1:0] floor_result_reg, ceil_result_reg;

    // Intermmediate wires out of fp_std_0
    logic [WIDTH - 1:0] result_o;
    logic [16:0] add_result_mantissa_o;
    logic [15:0] sub_result_mantissa_o;
    logic max_sign_o;
    logic min_sign_o;
    logic [WIDTH - 1:0] max_result_o;
    logic [WIDTH - 1:0] min_result_o;
    logic [7:0] max_exponent_o;


    /* Floating-point standard operations --> fp_std
        Addition, subtraction, max, min
    */

    fp_std_0 #(.WIDTH(WIDTH)) fp_std_0_inst (
        .clk_i(clk),
        .a_i(a),
        .b_i(b),
        .op_i(opcode),
        .result_o(std_result_stage1),
        .add_result_mantissa_o(add_result_mantissa_o),
        .sub_result_mantissa_o(sub_result_mantissa_o),
        .max_sign_o(max_sign_o),
        .min_sign_o(min_sign_o),
        .max_result_o(max_result_o),
        .min_result_o(min_result_o),
        .max_exponent_o(max_exponent_o)
    );

    fp_std_1 #(.WIDTH(WIDTH)) fp_std_1_inst (
        .clk_i(clk),
        .op_i(opcode_reg),
        .result_i(std_result_stage1),
        .add_result_mantissa_i(add_result_mantissa_o),
        .sub_result_mantissa_i(sub_result_mantissa_o),
        .max_sign_i(max_sign_o),
        .min_sign_i(min_sign_o),
        .max_result_i(max_result_o),
        .min_result_i(min_result_o),
        .max_exponent_i(max_exponent_o),
        .result_o(std_result_stage2)
    );

    fp_floor #(.WIDTH(WIDTH)) fp_floor_inst (
        .a(a_reg),
        .result(floor_result)
    );

    fp_ceil #(.WIDTH(WIDTH)) fp_ceil_inst (
        .a(a_reg),
        .result(ceil_result)
    );

    // Pipeline registers
    always_ff @(posedge clk) begin
        // Stage 1
        a_reg <= a;
        b_reg <= b;
        opcode_reg <= opcode;

        // Stage 2
        std_result_stage1_reg <= std_result_stage1;
        floor_result_reg <= floor_result;
        ceil_result_reg <= ceil_result;

        // Stage 3 (output)
        case (opcode_reg)
            4'b0000, 4'b0100, 4'b0001, 4'b0010: result <= std_result_stage2; // Add, Sub, Max, Min
            4'b1000: result <= floor_result_reg;
            4'b1001: result <= ceil_result_reg;
            default: result <= 'x; // Undefined operation
        endcase
    end

endmodule
