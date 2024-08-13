module alu (
    input   wire logic                  core_clock_i, //! Clock signal
    input   wire logic                  flush_i, //! Flush signal

    input   wire logic [31:0]           a, //! First operand from register bank a
    input   wire logic [31:0]           b, //! Second operand from register bank b / Immediate
    input   wire logic [6:0]            opc, //! Opcode from instruction
    input   wire logic [4:0]            dest_i, //! Destination register within bank
    input   wire logic                  bank_i, //! Bank number
    input   wire logic                  valid_i, //! current cycle is valid
    output       logic                  wb_reg_wen_o, //! Write register next cycle
    output       logic [31:0]           wb_result_o, //! Result to write
    output       logic [4:0]            wb_dest_o, //! Destination register within bank
    output       logic                  wb_bank_o, //! Bank number
    output       logic                  wb_valid_o, //! next cycle is valid
    output       logic                  wb_branch_exec_o, //! Branch instruction encountered
    output       logic                  wb_branch_taken_o //! Branch instruction taken
);
    initial wb_reg_wen_o = 0;
    initial wb_result_o = 0;
    initial wb_dest_o = 0;
    initial wb_bank_o = 0;
    initial wb_valid_o = 0;
    initial wb_branch_exec_o = 0;
    initial wb_branch_taken_o = 0;

    // 264 LUTs, 42 FFs, vivado synthesis defaults

    // Table of instructions
    // add = opc == 7'b0011000
    // sub = opc == 7'b0011001
    // xor = opc == 7'b0000000
    // and = opc == 7'b0001000
    // or  = opc == 7'b0010000
    // max = opc == 7'b0100011
    // maxu= opc == 7'b0100010
    // min = opc == 7'b0100001
    // minu= opc == 7'b0100000
    // lsl = opc == 7'b0101001
    // lsr = opc == 7'b0101000
    // asr = opc == 7'b0101010
    // beq = opc == 7'b1000100
    // bne = opc == 7'b1000110
    // blt = opc == 7'b1000011
    // bge = opc == 7'b1000001
    // bltu= opc == 7'b1000010
    // bgeu= opc == 7'b1000000
    
    wire [31:0] xor_result = a^b;
    wire [31:0] and_result = a&b;
    wire [31:0] or_result =  a|b;
    wire [31:0] add_result = opc[0] ? a-b : a+b;
    wire [31:0] cond_result;
    // shifter, default is shift right, to shift left it is op[0] = 1
    wire [31:0] shift_result;
    wire [4:0] shamt;
    assign shamt = b[4:0];
    wire [31:0] shift_operand1;
    
    for (genvar i = 0; i < 32; i++) begin : bit_rev1
        assign shift_operand1[i] = !opc[0] ? a[31-i] : a[i];
    end

    wire [31:0] shift_stage1;
    assign shift_stage1[31] = opc[1] ? a[31] : 1'b0;
    assign shift_stage1[30:0] = shift_operand1[31:1]; 

    wire [31:0] shift_res_stage1;
    assign shift_res_stage1 = shamt[0] ? shift_stage1 : shift_operand1;

    wire [31:0] shift_stage2;
    assign shift_stage2[31:30] =  opc[1] ? {{2{a[31]}}} : 2'b00;
    assign shift_stage2[29:0] = shift_res_stage1[31:2]; 

    wire [31:0] shift_res_stage2;
    assign shift_res_stage2 = shamt[1] ? shift_stage2 : shift_res_stage1;

    wire [31:0] shift_stage3;
    assign shift_stage3[31:28] =  opc[1] ? {{4{a[31]}}} : 4'b00;
    assign shift_stage3[27:0] = shift_res_stage2[31:4]; 

    wire [31:0] shift_res_stage3;
    assign shift_res_stage3 = shamt[2] ? shift_stage3 : shift_res_stage2;

    wire [31:0] shift_stage4;
    assign shift_stage4[31:24] =  opc[1] ? {{8{a[31]}}} : 8'b00;
    assign shift_stage4[23:0] = shift_res_stage3[31:8]; 

    wire [31:0] shift_res_stage4;
    assign shift_res_stage4 = shamt[3] ? shift_stage4 : shift_res_stage3;

    wire [31:0] shift_stage5;
    assign shift_stage5[31:16] =  opc[1] ? {{16{a[31]}}} : 16'b00;
    assign shift_stage5[15:0] = shift_res_stage4[31:16]; 

    wire [31:0] shift_res_stage5;
    assign shift_res_stage5 = shamt[4] ? shift_stage5 : shift_res_stage4;

    for (genvar i = 0; i < 32; i++) begin : bit_rev2
        assign shift_result[i] = !opc[0] ? shift_res_stage5[31-i] : shift_res_stage5[i];
    end

    wire lt_31 = a[30:0]<b[30:0];
    wire eq_32 = a==b;

    wire lt = {a[31],b[31]}==2'b00 ? lt_31 : {a[31],b[31]}==2'b01 ? 1'b0 : {a[31],b[31]}==2'b10 ? 1'b1 : lt_31;
    wire eq = eq_32;
    wire ge = !(lt);
    wire ltu = {a[31],b[31]}==2'b00 ? lt_31 : {a[31],b[31]}==2'b01 ? 1'b1 : {a[31],b[31]}==2'b10 ? 1'b0 : lt_31;
    wire geu = !{ltu};
    
    wire max = opc[0] ? ge : geu;
    wire min = opc[0] ? lt : ltu;
    wire [31:0] max_result = max ? a : b;
    wire [31:0] min_result = min ? a : b;
    assign cond_result = opc[1] ? max_result : min_result;

    wire gpu_branch_taken = opc[2:1]==2'b00 ? max : opc[2:1]==2'b01 ? min : opc[2:1]==2'b10 ? eq : !eq;
    always_ff @(posedge core_clock_i) begin : registered_alu_logic
        wb_valid_o <= !flush_i&valid_i;
        wb_branch_exec_o <= opc[6]&valid_i;
        wb_branch_taken_o <= gpu_branch_taken&valid_i;
        wb_dest_o <= dest_i;
        wb_reg_wen_o <= valid_i&(dest_i!=0);
        wb_bank_o <= bank_i;
        case (opc[5:3])
            3'b000: begin
                wb_result_o <= xor_result;
            end
            3'b001: begin
                wb_result_o <= and_result;
            end
            3'b010: begin
                wb_result_o <= or_result;
            end
            3'b011: begin
                wb_result_o <= add_result;
            end
            3'b100: begin
                wb_result_o <= shift_result;
            end
            3'b101: begin
                wb_result_o <= cond_result;
            end
        endcase
    end
    
endmodule
