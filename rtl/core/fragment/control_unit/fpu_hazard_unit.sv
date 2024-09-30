module fpu_hazard_unit #(
    parameter WIDTH = 32
)(
    input logic clk_i,
    input logic [WIDTH-1:0] fpu_instr_i,
    input logic execute_i, // signal that indicates executed fpu instruction that cycle

    output logic hazard_o,
    output logic valid_o,
    output logic [5:0] dest_o
);

    // 1 in Execution, 2 in Writeback
    // 1: currently computed in fpu
    // 2: currently written back by the fpu to the register file

    reg valid_1 = 0;
    reg valid_2 = 0;

    reg [5:0] dest_1 = 0;
    reg [5:0] dest_2 = 0;

    logic [5:0] source_1 = {1'b0, fpu_instr_i[18:14]}; // for register banking
    logic [5:0] source_2 = {1'b1, fpu_instr_i[23:19]};

    always_ff @(posedge clk_i) begin
        
        // Checks if fpu instruction was actually executed
        if (execute_i) begin
            valid_1 <= 1;
            dest_1 <= fpu_instr_i[14:9];
        end else begin
            valid_1 <= 0;
        end

        valid_2 <= valid_1;
        dest_2 <= dest_1;

        valid_o <= valid_2;
        dest_o <= dest_2;
    end

    logic source_1_hazard;
    logic source_2_hazard;

    assign source_1_hazard = (dest_1 == source_1 && valid_1) || (dest_2 == source_1 && valid_2);
    assign source_2_hazard = (dest_1 == source_2 && valid_1) || (dest_2 == source_2 && valid_2);

    assign hazard_o = source_1_hazard || source_2_hazard;
    
endmodule
