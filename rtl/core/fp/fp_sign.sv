module fp_sign #(
    parameter WIDTH = 24
)(
    input  wire logic [WIDTH - 1:0] a,
    output logic [WIDTH - 1:0] result
);

    logic result_sign;
    assign result_sign = a[23];

    always_comb begin
        
        if (result_sign == 1'b0) begin
            result = 24'h3f8000; 
        end else begin
            result = 24'hbf8000;
        end

    end

endmodule
