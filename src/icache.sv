module icache #(
    parameter   ADDR_WIDTH = 32, 
                DATA_WIDTH = 32
)
(
    input   wire logic                      clk,
    
    input   wire logic [9:0]                rd_addr,
    input   wire logic                      rd_en,
    output  logic [31:0]                    rd_data,

    input   wire logic [9:0]                wr_addr,
    input   wire logic [DATA_WIDTH-1:0]     wr_data,
    input   wire logic                      wr_en

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

    // 32-bits x 512 words = 16 kbits = 2 kBytes, which is half a ~4kByte BRAM
    reg[31:0] mem[511:0]; // Calls the BRAM, 512 words of 32 bits each

    /* Direct mapped cache
        | tag | set | byte offset |
        | 21 | 4 | 7 | -> 32

        | v | tag | data |
        | 1 | 21 | 128 | -> 150
    */

    always_ff @(posedge clk) begin
        ram[wr_addr] <= wr_en ? wr_data : ram[wr_addr];
        rd_data <= rd_en ? ram[rd_addr] : rd_data; 
    end

    // Cache read logic

    always_comb begin
        tag = rd_addr[31:];
        set = rd_addr[:7];
        byte_offset = rd_addr[6:0];
    end

endmodule