module fragment #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter CACHE_SIZE = 512
) (
    input wire logic clk,
    input wire logic rst,

    input wire logic icache_flush,
    input wire logic [31:0] set_pc,
    input wire logic set_pc_valid,
    // Master interface
    output logic                    icache_a_valid,
    input wire logic                icache_a_ready,
    output logic [31:0]             icache_a_addr,

    // Slave interface
    input wire logic                icache_d_valid,
    input wire [31:0]               icache_d_data
);
logic [31:0]    instr;
logic           stall;
logic           valid;

    icache_controller ictrl0 (clk,
    rst, 
    instr,stall,valid,icache_flush,set_pc,set_pc_valid,icache_a_valid,
    icache_a_ready,
    icache_a_addr,
    icache_d_valid,
    icache_d_data);

    wire flush;
    wire logic [127:0]    alu_a_o;
    wire logic [127:0]    alu_b_o;
    wire logic [6:0]            alu_opc_o;
    wire logic [4:0]            alu_dest_o;
    wire logic                  alu_bank_o;
    wire logic                  alu_valid_o;

    wire logic                  alu_wb_reg_wen_i;
    wire logic [127:0]          alu_wb_result_i;
    wire logic [4:0]            alu_wb_dest_i;
    wire logic                  alu_wb_bank_i;
    wire logic                  alu_wb_valid_i;
    wire logic [3:0]            alu_wb_branch_exec_i;
    wire logic [3:0]            alu_wb_branch_taken_i;
    logic [95:0] fpu_a_o;
    logic [95:0] fpu_b_o;
    logic [3:0]  fpu_opcode_o;
    logic [95:0] fpu_result_i;
    logic [23:0] sfu_core_operand_o;
    logic [2:0]     sfu_core_special_op_o;
    logic           sfu_valid_o;
    logic [23:0]    sfu_core_result_i;
    logic           sfu_core_valid_i;
    wire logic [23:0]               texture_s_o;
    wire logic [23:0]               texture_t_o;
    wire logic                      texture_lkp_o;
    wire logic [23:0]               texture_i;
    wire logic                      texture_valid_i;
    wire logic [31:0]               dc_addr_o;
    wire logic [31:0]               dc_data_o;
    wire logic [2:0]                dc_op_o;
    wire logic                      dc_valid_o;
       logic [31:0]               dc_data_i;
       logic                      dc_valid_i;
    control_unit ctrl0 (clk, rst, instr, valid, stall, flush, alu_a_o,
    alu_b_o,
    alu_opc_o,
    alu_dest_o,
    alu_bank_o,
    alu_valid_o,
    alu_wb_reg_wen_i,
    alu_wb_result_i,
    alu_wb_dest_i,
    alu_wb_bank_i,
    alu_wb_valid_i,
    alu_wb_branch_exec_i,
    alu_wb_branch_taken_i, fpu_a_o,
    fpu_b_o,
    fpu_opcode_o,
    fpu_result_i,sfu_core_operand_o,sfu_core_special_op_o,
    sfu_valid_o,
    sfu_core_result_i,
    sfu_core_valid_i,  texture_s_o,
    texture_t_o,
    texture_lkp_o,
    texture_i,
    texture_valid_i,
    dc_addr_o,
    dc_data_o,
    dc_op_o,
    dc_valid_o,
    dc_data_i,
    dc_valid_i);

    generate
        for (genvar i = 0; i < 4; i++) begin : instantiate_alus
            alu alu (clk, rst, alu_a_o[((i+1)*32)-1:(i*32)], alu_b_o[((i+1)*32)-1:(i*32)], alu_opc_o, alu_dest_o,
            alu_bank_o, alu_valid_o, alu_wb_reg_wen_i,
            alu_wb_result_i[((i+1)*32)-1:(i*32)],
            alu_wb_dest_i,
            alu_wb_bank_i,
            alu_wb_valid_i,
            alu_wb_branch_exec_i[i],
            alu_wb_branch_taken_i[i]);
        end
    endgenerate

    generate
        for (genvar i = 0; i < 4; i++) begin : instantiate_fpus
            fpu #(24) fpu (clk, fpu_a_o[((i+1)*24)-1:(i*24)],
            fpu_b_o[((i+1)*24)-1:(i*24)],
            fpu_opcode_o,
            fpu_result_i[((i+1)*24)-1:(i*24)]);
        end
    endgenerate
endmodule
