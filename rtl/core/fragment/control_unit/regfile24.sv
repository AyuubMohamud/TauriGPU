module regfile24 (
    input   wire logic                  core_clock_i, //! Clock signal

    input   wire logic [4:0]            source_i, //! Source register
    output  wire logic [23:0]           source_data_o, //! Source register

    input   wire logic [4:0]            dest_i, //! Destination register
    input   wire logic [23:0]           data_w_i, //! Data to write to register
    input   wire logic                  dest_we_i //! Data write enable
);
    // 16 LUTs
    reg [23:0] rf [0:31]; //! 24-bit Register file bank
    initial begin
        for (integer i = 0; i < 32; i++) begin
            rf[i] = 0;
        end
    end
    always_ff @(posedge core_clock_i) begin : register_write
        if (dest_we_i) begin
            rf[dest_i] <= data_w_i;
        end
    end
    assign source_data_o = rf[source_i];
endmodule
