module tcbram (
    input   wire logic                  core_clock_i,
    
    input   wire logic [8:0]            rd_addr_i,
    output  wire logic [31:0]           rd_data_o,

    input   wire logic [3:0]            wr_en_i,
    input   wire logic [8:0]            wr_addr_i,
    input   wire logic [31:0]           wr_data_i
);
    reg [31:0] ram [0:511];
    always_ff @(posedge core_clock_i) begin
        rd_data_o <= ram[rd_addr_i];
        if (wr_en_i[3]) begin
            ram[wr_addr_i][31:24] <= wr_data_i[31:24];
        end
        if (wr_en_i[2]) begin
            ram[wr_addr_i][23:16] <= wr_data_i[23:16];
        end
        if (wr_en_i[1]) begin
            ram[wr_addr_i][15:8] <= wr_data_i[15:8];
        end
        if (wr_en_i[0]) begin
            ram[wr_addr_i][7:0] <= wr_data_i[7:0];
        end
    end
endmodule
