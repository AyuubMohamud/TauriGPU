module icache_controller (
    // input logic clk,
    // input logic reset,
    // output logic [31:0] instruction

    output       logic [2:0]                icache_a_opcode,
    output       logic [2:0]                icache_a_param,
    output       logic [3:0]                icache_a_size,
    output       logic [31:0]               icache_a_address,
    output       logic [3:0]                icache_a_mask,
    output       logic [31:0]               icache_a_data,
    output       logic                      icache_a_corrupt,
    output       logic                      icache_a_valid,
    input   wire logic                      icache_a_ready,

    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                icache_d_opcode,
    input   wire logic [1:0]                icache_d_param,
    input   wire logic [3:0]                icache_d_size,
    input   wire logic                      icache_d_denied,

    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [31:0]               icache_d_data,
    
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic                      icache_d_corrupt,
    
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic                      icache_d_valid,
    output  wire logic                      icache_d_ready
);

    

endmodule