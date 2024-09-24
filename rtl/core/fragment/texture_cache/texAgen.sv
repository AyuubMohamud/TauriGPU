module texAgen (
    input   wire logic [10:0] x,
    input   wire logic [10:0] y,

    input   wire logic [10:0] tx_height,

    output  wire logic [21:0] tx_out
);
    wire [21:0] product = y*tx_height+{11'h0, x};
    assign tx_out = product;
endmodule
