`include "def.sv"

module control_unit #(
    parameter WIDTH = 32,
    parameter ALU_WIDTH = 32,
    parameter FPU_WIDTH = 24,
    parameter SFU_WIDTH = 24
)(
    input logic clk_i,
    input logic [WIDTH-1:0] instr_i,

    output logic stall_o,
    output logic flush_o,

    // ALU control signals

    output logic [4*WIDTH-1:0] alu_a_o,
    output logic [4*WIDTH-1:0] alu_b_o,
    output logic [6:0] alu_opc_o,
    output logic [4:0] alu_dest_o,
    output logic alu_bank_o,
    output logic alu_valid_o,

    input logic [3:0] alu_wb_reg_wen_i,
    input logic [4*WIDTH-1:0] alu_wb_result_i,
    input logic [4*4:0] alu_wb_dest_i,
    input logic [3:0] alu_wb_bank_i,
    input logic [3:0] alu_wb_valid_i,
    input logic [3:0] alu_wb_branch_exec_i,
    input logic [3:0] alu_wb_branch_taken_i,

    // FPU control signals

    output logic [4*FPU_WIDTH-1:0] fpu_a_o,
    output logic [4*FPU_WIDTH-1:0] fpu_b_o,
    output logic [3:0] fpu_opcode_o,

    input logic [4*FPU_WIDTH-1:0] fpu_result_i,

    // SFU control signals

    output logic [23:0] sfu_core_operand_o,
    output logic [2:0] sfu_core_special_op_o,
    output logic sfu_valid_o,

    input logic [23:0] sfu_core_result_i,
    input logic sfu_core_valid_i,

    // Data cache control signals

);

    



    
endmodule
