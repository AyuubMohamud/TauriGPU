`include "def.sv"

module control_unit #(
    parameter WIDTH = 32,
    parameter ALU_WIDTH = 32,
    parameter FPU_WIDTH = 24,
    parameter SFU_WIDTH = 24
)(
    input logic clk_i,
    input logic rst_i,
    input logic [WIDTH-1:0] instr_i, // icache controller
    input logic valid_i, // icache controller

    output logic stall_o, // icache controller
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

<<<<<<< Updated upstream:rtl/core/control_unit/control_unit.sv
=======
    output   wire logic [23:0]               texture_s_o,
    output   wire logic [23:0]               texture_t_o,
    output   wire logic                      texture_lkp_o,

    input    wire logic [23:0]               texture_i,
    input    wire logic                      texture_valid_i,

    output   wire logic [31:0]               dc_addr_o,
    output   wire logic [31:0]               dc_data_o,
    output   wire logic [2:0]                dc_op_o,
    output   wire logic                      dc_valid_o,

    input       logic [31:0]               dc_data_i,
    input       logic                      dc_valid_i

>>>>>>> Stashed changes:rtl/core/fragment/control_unit/control_unit.sv
);

    wire sfifo_full;
    wire sfifo_empty;
    wire [WIDTH-1:0] sfifo_data;
    wire sfifo_read;

    sfifo2 #(
        .DW(WIDTH),
        .FW(16)
    ) sfifo_inst (
        .i_clk(clk_i),
        .i_reset(rst_i),
        .i_wr_en(valid_i && ~sfifo_full),
        .i_wr_data(instr_i),
        .o_full(sfifo_full),
        .i_rd(sfifo_read),
        .o_rd_data(sfifo_data),
        .o_empty(sfifo_empty)
    );

    assign stall_o = sfifo_full;

    logic [1:0] instr_type = instr_i[1:0];

    localparam IDLE = 2'b00; // ALU and FPU are idle
    localparam MEM = 2'b10;
    localparam SFU = 2'b11;

    reg [1:0] control_state = IDLE;

    logic [1:0] counter = 2'b00;

    // Bit fields

    assign source_reg_b = instr_i[31:19];
    assign source_reg_a = instr_i[18:14];
    assign immediate = instr_i[15];
    assign dest_reg = instr_i[14:9];
    assign opcode = instr_i[8:2];
    assign instr_type = instr_i[1:0];

    // Hazard unit

    

    /*
        IDLE state
            servers all ALU and FPU instructions
            as long as the instructions don't have any hazards
            they are read and dispatched to the respective units

            however, if the instruction is a memory instruction
            it transitions to the MEM state and does not read from the FIFO

            same for SFU, but transitions to SFU state

        MEM state
            serves memory instructions
            dispatches instruction 4 different times for each 4 register file (SEU)
            wait until the dcache is finished for all 4 register files
            then transition to IDLE state

        SFU state
            serves SFU instructions
            dispatches instruction 4 different times for each 4 register file (SEU)
            wait until the SFU is finished for all 4 register files
            then transition to IDLE state

        Counter
            when the counter reaches 3, and either the dcache or the SFU raises
            its done signal (increments the counter and wraps around to 0), 
            the control unit transitions to the IDLE state
            and reads from the FIFO
    */

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            control_state <= IDLE;
        end else begin
            case (control_state)
                IDLE: begin
                    if (instr_type == 2'b00) begin
                        control_state <= IDLE;
                    end else if (instr_type == 2'b01) begin
                        control_state <= MEM;
                    end else if (instr_type == 2'b10) begin
                        control_state <= SFU;
                    end
                end
                MEM: begin
                    control_state <= IDLE;
                end
                SFU: begin
                    control_state <= IDLE;
                end
            endcase
        end
    end

    // Branch logic

    

endmodule
