module fp_abs #(
    parameter WIDTH = 24
)(
    input  wire [WIDTH - 1:0] a,
    output wire [WIDTH - 1:0] result
);
    // Extract the sign bit and make the value positive
    assign result = {1'b0, a[WIDTH - 2:0]};
endmodule
