module texToInteger (
    input   wire logic [14:0] s,
    input   wire logic [14:0] t,
    input   wire logic [10:0] tx_width,
    input   wire logic [10:0] tx_height,

    output  wire logic [10:0] txWidth_o,
    output  wire logic [10:0] txHeight_o
);
    wire [25:0] product_x = s*tx_width;
    wire [25:0] product_y = t*tx_height;

    assign txWidth_o = product_x[25:15];
    assign txHeight_o = product_y[25:15];
    
endmodule
