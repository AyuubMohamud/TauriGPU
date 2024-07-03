module fp_neg (
    input  wire [31:0] a,
    output wire [31:0] result
);
    // Flip the sign bit
    assign result = {~a[31], a[30:0]};
endmodule
