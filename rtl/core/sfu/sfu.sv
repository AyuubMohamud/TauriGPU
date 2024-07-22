module sfu (
    input   wire logic                  core_clock_i,
    input   wire logic                  flush_i,

    input   wire logic [23:0]           core_operand,
    input   wire logic [2:0]            core_special_op,
    input   wire logic                  valid,


    output       logic [23:0]           core_result,
    output       logic                  core_valid
);
    wire logic [9:0]    rsqrt_rd_addr;
    wire logic          rsqrt_rd_en;
    wire logic [15:0]   rsqrt_rd_data;
    wire logic [9:0]    tranc_rd_addr;
    wire logic          tranc_rd_en;
    wire logic [15:0]   tranc_rd_data;
    SFULookup #("rsqrt.mem") rsqrt (core_clock_i, rsqrt_rd_addr, rsqrt_rd_en, rsqrt_rd_data);
    SFULookup #("tranc.mem") tranc (core_clock_i, tranc_rd_addr, tranc_rd_en, tranc_rd_data);

    
endmodule
