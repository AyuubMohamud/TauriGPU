module alu_hazard_unit #(
    parameter WIDTH = 32
)(
    input logic clk_i,
    input logic [WIDTH-1:0] alu_instr_i,
    input logic execute_i, // signal that indicates executed ALU instruction that cycle

    output logic hazard_o
);

    /*
        Avoid: 
        - Read after Write (RAW)
        - Write after Read (WAR)

        dest_1 and dest_2 contain the destination register of the ALU instructions
        in execution and writeback respectively. The logic below checks whether the current
        ALU instruction's source registers are the same as the destination registers of the
        ALU instruction in execution and in writeback. If they are, a hazard is detected.

        how to find the instruction that is being produced by the ALU?
        **a chain of two flip-flops**, two valid registers, two destination registers
        either they are both not valid or they are both valid but conflict
    */

    // 1 in Execution, 2 in Writeback
    // 1: currently computed in ALU
    // 2: currently written back by the ALU to the register file

    reg valid_1 = 0;
    reg valid_2 = 0;

    reg [5:0] dest_1 = 0;
    reg [5:0] dest_2 = 0;

    logic [5:0] source_1 = {1'b0, alu_instr_i[18:14]}; // for register banking
    logic [5:0] source_2 = {1'b1, alu_instr_i[23:19]};

    always_ff @(posedge clk_i) begin
        
        // Checks if ALU instruction was actually executed
        if (execute_i) begin
            valid_1 <= 1;
            dest_1 <= alu_instr_i[14:9];
        end else begin
            valid_1 <= 0;
        end

        valid_2 <= valid_1;
        dest_2 <= dest_1;

    end

    logic source_1_hazard;
    logic source_2_hazard;

    assign source_1_hazard = (dest_1 == source_1 && valid_1) || (dest_2 == source_1 && valid_2);
    assign source_2_hazard = (dest_1 == source_2 && valid_1) || (dest_2 == source_2 && valid_2);

    assign hazard_o = source_1_hazard || source_2_hazard;

endmodule
