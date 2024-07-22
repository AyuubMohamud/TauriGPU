module SFULookup #(parameter romtable = "") (
    input   wire logic          clock,

    input   wire logic [9:0]    rd_addr,
    input   wire logic          rd_en,
    output       logic [15:0]   rd_data
);
    reg [15:0] ram [1023:0];
    initial begin
        $readmemh(romtable, ram);
    end
    always_ff @(posedge clock) begin
        rd_data <= rd_en ? ram[rd_addr] : rd_data;
    end
endmodule
