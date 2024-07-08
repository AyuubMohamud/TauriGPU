module fp_floor #(
    parameter WIDTH = 24
)(
    input  wire logic [WIDTH - 1:0] a,
    output wire logic [WIDTH - 1:0] result
);

    logic [7:0] exponent = a[22:15];
    logic [14:0] mask;

    assign mask = {
        exponent>8'd128, exponent>8'd129, exponent>8'd130,
        exponent>8'd131, exponent>8'd132, exponent>8'd133, exponent>8'd134,
        exponent>8'd135, exponent>8'd136, exponent>8'd137, exponent>8'd138,
        exponent>8'd139, exponent>8'd140, exponent>8'd141, exponent>8'd142
    };

    assign result = exponent<8'd127 ? 0 : {a[23:15], a[14:0]&mask};

endmodule
