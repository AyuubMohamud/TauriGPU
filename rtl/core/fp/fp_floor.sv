module fp_floor #(
    parameter WIDTH = 24
)(
    input wire [WIDTH-1:0] a,
    output logic [WIDTH-1:0] result
);

    /*
        Method: Create a mask based on exponent value. 
        This mask is used to keep the integer part of the fraction and zero out the fractional part. 
        Done by checking if the exponent is greater than 127, 128, 129, ..., 141.
    */

    wire sign = a[23];
    wire [7:0] exponent = a[22:15];
    wire [14:0] fraction = a[14:0];
    
    wire [14:0] mask;
    wire [14:0] inverted_mask;
    wire [14:0] rounded_fraction;
    wire has_fraction;

    // Create mask for rounding
    assign mask = {
        exponent>8'd127, exponent>8'd128, exponent>8'd129,
        exponent>8'd130, exponent>8'd131, exponent>8'd132, exponent>8'd133,
        exponent>8'd134, exponent>8'd135, exponent>8'd136, exponent>8'd137,
        exponent>8'd138, exponent>8'd139, exponent>8'd140, exponent>8'd141
    };

    assign inverted_mask = ~mask;
    assign rounded_fraction = fraction & mask;
    assign has_fraction = |(fraction & inverted_mask);

    always_comb begin
        if (exponent < 8'd127) begin
            // If the absolute value is less than 1
            result = sign ? 24'h800000 : 24'h000000; // -1 or 0
        end else if (!sign) begin
            // Positive numbers: round towards zero
            result = {a[23:15], rounded_fraction};
        end else begin
            // Negative numbers: round away from zero if there's a fraction
            if (has_fraction) begin
                // If there's a fraction, we need to round down (away from zero)
                if (rounded_fraction == 15'b0) begin
                    /* If rounding causes a rollover, adjust the exponent
                        Rollover meaning:
                        Check if rounded fraction is 0
                    */
                    result = {1'b1, exponent + 8'd1, 15'b0};
                end else begin
                    result = {1'b1, exponent, rounded_fraction} + 24'd1;
                end
            end else begin
                // If it's already an integer, keep it as is
                result = a;
            end
        end
    end

endmodule
