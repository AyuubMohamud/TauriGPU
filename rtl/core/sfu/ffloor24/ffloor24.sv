module ffloor24 (
    input   wire logic [7:0] exponent,
    output  wire logic [14:0] mask
);
    assign mask = {
    exponent>8'd128, exponent>8'd129, exponent>8'd130,
    exponent>8'd131, exponent>8'd132, exponent>8'd133, exponent>8'd134,
    exponent>8'd135, exponent>8'd136, exponent>8'd137, exponent>8'd138,
    exponent>8'd139, exponent>8'd140, exponent>8'd141, exponent>8'd142
    };
endmodule
