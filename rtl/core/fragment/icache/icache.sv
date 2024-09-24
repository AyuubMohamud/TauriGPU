module icache #(
    parameter   WIDTH = 32
)
(
    input   wire logic                      clk,
    
    input   wire logic [8:0]                rd_addr,
    input   wire logic                      rd_en,
    output  logic [WIDTH-1:0]               rd_data,

    input   wire logic [8:0]                wr_addr,
    input   wire logic [WIDTH-1:0]          wr_data,
    input   wire logic                      wr_en
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
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
        if (rd_en) begin
            rd_data <= mem[rd_addr];
        end
    end

endmodule
