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


    fp_std_0 #(.WIDTH(WIDTH)) fp_std_0_inst (
        .a(a_reg),
        .b(b_reg),
        .opcode(opcode_reg),
        .result(std_result_stage1)
    );

    fp_std_1 #(.WIDTH(WIDTH)) fp_std_1_inst (
        .a(std_result_stage1_reg),
        .opcode(opcode_reg),
        .result(std_result_stage2)
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
            4'b0000, 4'b0001, 4'b0010: result <= std_result_stage2; // Add, Sub, Max, Min
            4'b1000: result <= floor_result_reg;
            4'b1001: result <= ceil_result_reg;
            default: result <= 'x; // Undefined operation
        endcase
    end

endmodule