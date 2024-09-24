module max3 (
    input   wire logic [11:0]   a,
    input   wire logic [11:0]   b,
    input   wire logic [11:0]   c,

    output  wire logic [11:0]   d
);
    wire [11:0] intermediate;
    assign intermediate = b > c ? b : c;

    assign d = a > intermediate ? a : intermediate;
endmodule
