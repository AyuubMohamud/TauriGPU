// `include "def.sv"

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

    input logic alu_wb_reg_wen_i,
    input logic [4*WIDTH-1:0] alu_wb_result_i,
    input logic [4:0] alu_wb_dest_i,
    input logic alu_wb_bank_i,
    input logic alu_wb_valid_i,
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

    output   wire logic [23:0]               texture_s_o,
    output   wire logic [23:0]               texture_t_o,
    output   wire logic                      texture_lkp_o,

    input  wire logic [23:0]               texture_i,
    input  wire logic                      texture_valid_i,

    output   wire logic [31:0]               dc_addr_o,
    output   wire logic [31:0]               dc_data_o,
    output   wire logic [2:0]                dc_op_o,
    output   wire logic                      dc_valid_o,

    input       logic [31:0]               dc_data_i,
    input       logic                      dc_valid_i

);

    // Extract data from FIFO 

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

    logic [1:0] instr_type = sfifo_data[1:0];

    reg [1:0] control_state = IDLE;

    logic [1:0] counter = 2'b00;

    // For register file banks

    wire [31:0] int_source_data_a[3:0];
    wire [31:0] int_source_data_b[3:0];

    wire [23:0] fp_source_data_a[3:0];
    wire [23:0] fp_source_data_b[3:0];

    // Bit fields

    logic [4:0] source_reg_b = sfifo_data[25:21];
    logic [4:0] source_reg_a = sfifo_data[20:16];
    logic [31:0] imm = {{22{sfifo_data[31]}}, sfifo_data[30:21]};
    logic imm_exist = sfifo_data[15];
    logic [5:0] dest_reg = sfifo_data[14:9]; // top bit for bank you write to

    // Hazard unit

    wire alu_execute;
    wire alu_hazard;

    alu_hazard_unit #(
        .WIDTH(WIDTH)
    ) alu_hazard_unit_inst (
        .clk_i(clk_i),
        .alu_instr_i(sfifo_data),
        .execute_i(alu_execute),
        .hazard_o(alu_hazard)
    );

    wire fpu_execute;
    wire fpu_hazard;

    wire [5:0] dest_reg_fpu;
    wire valid_fpu;

    fpu_hazard_unit #(
        .WIDTH(WIDTH)
    ) fpu_hazard_unit_inst (
        .clk_i(clk_i),
        .fpu_instr_i(sfifo_data),
        .execute_i(fpu_execute),
        .hazard_o(fpu_hazard),
        .dest_o(dest_reg_fpu),
        .valid_o(valid_fpu)
    );

    // Driving register control signals

    wire [5:0] int_wr_source;
    wire [5:0] fp_wr_source;

    wire [31:0] int_wr_data[3:0];
    wire [23:0] fp_wr_data[3:0];

    wire [3:0] int_we_a;
    wire [3:0] int_we_b;
    wire [3:0] fp_we_a;
    wire [3:0] fp_we_b;

    assign sfifo_read = fpu_execute || alu_execute || ((dc_valid_i || texture_valid_i) && counter == 3) || (sfu_core_valid_i && counter == 3);

    assign int_wr_source = dc_valid_i ? dest_reg : {alu_wb_bank_i, alu_wb_dest_i};

    assign fp_wr_source = (dc_valid_i || texture_valid_i || sfu_core_valid_i) ? dest_reg : dest_reg_fpu;

    genvar i;

    generate;
        for (i = 0; i < 4; i++) begin
            assign int_wr_data[i] = dc_valid_i ? dc_data_i : alu_wb_result_i[32*(i+1)-1:i*32];
            assign fp_wr_data[i] = dc_valid_i ? dc_data_i[31:8] : (texture_valid_i ? texture_i : (sfu_core_valid_i ? sfu_core_result_i : fpu_result_i[24*(i+1)-1:24*i]));

            assign int_we_a[i] = (dc_valid_i && sfifo_data[5] && !dest_reg[5]) || (alu_wb_valid_i && !alu_wb_bank_i);
            assign int_we_b[i] = (dc_valid_i && sfifo_data[5] && dest_reg[5]) || (alu_wb_valid_i && alu_wb_bank_i);
            
            assign fp_we_a[i] = (sfu_core_valid_i && !dest_reg[5]) || (valid_fpu && !dest_reg_fpu[5]) || (dc_valid_i && !sfifo_data[5] && !dest_reg[5]) || (texture_valid_i && !dest_reg[5]);
            assign fp_we_b[i] = (sfu_core_valid_i && dest_reg[5]) || (valid_fpu && dest_reg_fpu[5]) || (dc_valid_i && !sfifo_data[5] && dest_reg[5]) || (texture_valid_i && dest_reg[5]);
        end
    endgenerate

    assign alu_execute = !alu_hazard && (instr_type == 2'b00) && !sfifo_empty;
    assign fpu_execute = !fpu_hazard && (instr_type == 2'b01) && !sfifo_empty;

    // Register files

    generate 
        for (i = 0; i < 4; i++) begin
            regfile24 regfile24_bank_a (
                .core_clock_i(clk_i),
                .source_i(source_reg_a),
                .source_data_o(fp_source_data_a[i]),
                .dest_i(fp_wr_source[4:0]),
                .data_w_i(fp_wr_data[i]),
                .dest_we_i(fp_we_a[i])
            );

            regfile24 regfile24_bank_b (
                .core_clock_i(clk_i),
                .source_i(source_reg_b),
                .source_data_o(fp_source_data_b[i]),
                .dest_i(fp_wr_source[4:0]), // effectively: {fp_we_b, fp_wr_source[4:0]}
                .data_w_i(fp_wr_data[i]),
                .dest_we_i(fp_we_b[i])
            );
        end
    endgenerate

    generate 
        for (i = 0; i < 4; i++) begin
            regfile32 regfile32_inst_bank_a (
                .core_clock_i(clk_i),
                .source_i(source_reg_a),
                .source_data_o(int_source_data_a[i]),
                .dest_i(int_wr_source[4:0]),
                .data_w_i(int_wr_data[i]),
                .dest_we_i(int_we_a[i])
            );

            regfile32 regfile32_inst_bank_b (
                .core_clock_i(clk_i),
                .source_i(source_reg_b),
                .source_data_o(int_source_data_b[i]),
                .dest_i(int_wr_source[4:0]),
                .data_w_i(int_wr_data[i]),
                .dest_we_i(int_we_b[i])
            );
        end
    endgenerate

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

    localparam IDLE = 2'b00; // ALU and FPU are idle
    localparam MEM = 2'b10;
    localparam SFU = 2'b11;

    reg requested; // requested by the ALU or FPU or SFU

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            control_state <= IDLE;
        end else begin
            case (control_state)
                IDLE: begin
                    if (instr_type == 2'b00) begin
                        if (!alu_hazard) begin
                            control_state <= IDLE;
                            alu_a_o <= {int_source_data_a[3], int_source_data_a[2], int_source_data_a[1], int_source_data_a[0]};
                            if (imm_exist) begin
                                alu_b_o <= {imm, imm, imm, imm};
                            end else begin
                                alu_b_o <= {int_source_data_b[3], int_source_data_b[2], int_source_data_b[1], int_source_data_b[0]};
                            end
                            alu_opc_o <= sfifo_data[8:2];
                            alu_dest_o <= dest_reg[4:0];
                            alu_bank_o <= dest_reg[5];
                            alu_valid_o <= 1;
                        end else begin
                            alu_valid_o <= 0;
                        end
                    end else if (instr_type == 2'b01) begin
                        alu_valid_o <= 0;
                        if (!fpu_hazard) begin
                            control_state <= IDLE;
                            fpu_a_o <= {fp_source_data_a[3], fp_source_data_a[2], fp_source_data_a[1], fp_source_data_a[0]};
                            fpu_b_o <= {fp_source_data_b[3], fp_source_data_b[2], fp_source_data_b[1], fp_source_data_b[0]};
                            fpu_opcode_o <= sfifo_data[5:2];
                        end
                    end else if (instr_type == 2'b10) begin
                        alu_valid_o <= 0;
                        control_state <= MEM;
                    end else if (instr_type == 2'b11) begin
                        alu_valid_o <= 0;
                        control_state <= SFU;
                    end
                end
                MEM: begin
                    if (dc_valid_i || texture_valid_i) begin
                        counter <= counter + 1;
                        if (counter == 3) begin
                            control_state <= IDLE;
                        end
                    end
                    if (!requested) begin
                        requested <= 1;
                        if (!sfifo_data[6]) begin // Checks data or texture cache
                            dc_valid_o <= 1;
                            dc_data_o <= sfifo_data[5] ? int_source_data_b[counter] : {fp_source_data_a[counter], 8'h00};
                            dc_addr_o <= int_source_data_a[counter];
                            dc_op_o <= sfifo_data[4:2];
                        end else begin
                            texture_lkp_o <= 1;
                            texture_s_o <= fp_source_data_a[counter];
                            texture_t_o <= fp_source_data_b[counter];
                        end
                    end else begin
                        requested <= (dc_valid_i || texture_valid_i) ? 0 : 1;
                        dc_valid_o <= 0;
                        texture_lkp_o <= 0;
                    end
                end
                SFU: begin
                    if (sfu_core_valid_i) begin
                        counter <= counter + 1;
                        if (counter == 3) begin
                            control_state <= IDLE;
                        end
                    end
                    if (!requested) begin // always requests until counter reaches IDLE
                        requested <= 1;
                        sfu_valid_o <= 1;
                        sfu_core_operand_o <= fp_source_data_a[counter]; // SIMT, different pixels in different registers / threads
                        sfu_core_special_op_o <= sfifo_data[4:2]; // ooh, embarrassingly parallel
                    end else begin
                        requested <= sfu_core_valid_i ? 0 : 1;
                        sfu_valid_o <= 0;
                    end
                end
            endcase
        end
    end

    // Branch logic
        // To be implemented
    

endmodule
