module fp_neg #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH - 1:0] a,
    output wire [WIDTH - 1:0] result
);
    // Flip the sign bit
    assign result = {~a[WIDTH - 1], a[WIDTH - 2:0]};
endmodule
