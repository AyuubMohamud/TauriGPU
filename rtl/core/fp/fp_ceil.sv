module fp_ceil #(
    parameter WIDTH = 24
)(
    input wire [WIDTH-1:0] a,
    output logic [WIDTH-1:0] result
);

    // 1. Extract fields from input
    wire sign;
    wire [7:0] exponent;
    wire [14:0] fraction;

    wire is_integer;
    wire [7:0] shift_amount;
    wire [14:0] fraction_mask;
    wire has_fraction;
    wire [14:0] increment;

    logic [14:0] new_fraction;
    logic [7:0] new_exponent;
    logic new_sign;

    assign sign = a[23];
    assign exponent = a[22:15];
    assign fraction = a[14:0];
    
    // 2. Determine if the input is already an integer
    assign is_integer = (exponent >= 8'd150) || (fraction == 15'b0);
    
    // Calculate how many bits of the fraction represents the fractional part
    assign shift_amount = 8'd150 - exponent;
    
    // Mask for the fractional part (all 1s for the fractional part)
    assign fraction_mask = (15'h7fff >> shift_amount);
    
    // Determine if rounding is needed by checking if the fractional part is non-zero
    assign has_fraction = (fraction & fraction_mask) != 15'b0;
    
    // Increment value for rounding
    assign increment = 15'h4000 >> (8'd14 - shift_amount);
    
    // Perform ceiling operation
    always_comb begin
        if (is_integer) begin
            // already integer, keep original value
            {new_sign, new_exponent, new_fraction} = a;
        end else if (!sign && has_fraction) begin
            // positive non-integer, round up
            {new_sign, new_exponent, new_fraction} = {1'b0, exponent, fraction} + {9'b0, increment};
        end else if (sign && has_fraction) begin
            // negative non-integer, truncate (e.g. -2.8 -> -2)
            new_sign = 1'b1;
            new_exponent = exponent;
            new_fraction = fraction & ~fraction_mask;
        end else begin
            {new_sign, new_exponent, new_fraction} = a;
        end
    end

    assign result = {new_sign, new_exponent, new_fraction};

endmodule
