module fp_abs (
    input  wire [31:0] a,
    output wire [31:0] result
);
    // Extract the sign bit and make the value positive
    assign result = {1'b0, a[30:0]};
endmodule
