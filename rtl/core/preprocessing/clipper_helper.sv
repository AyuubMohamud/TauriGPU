module clipper_helper(
    input logic signed [31:0] calc_t_num, calc_t_den,
    output logic signed [31:0] calc_t_result,
    input logic signed [31:0] interp_v1, interp_v2, interp_t,
    output logic signed [31:0] interp_result
);

    // Define constants for fixed-point arithmetic
    localparam FIXED_POINT_SHIFT = 8;

    // calc_t logic
    logic sign;
    logic signed [31:0] num, den, t, prod;
    integer i;

    always_comb begin
        // Determine the sign of the result
        sign = (calc_t_num[31] ^ calc_t_den[31]) ? 1'b1 : 1'b0;
        
        // Take absolute values
        num = calc_t_num[31] ? -calc_t_num : calc_t_num;
        den = calc_t_den[31] ? -calc_t_den : calc_t_den;

        t = 0;
        for (i = FIXED_POINT_SHIFT - 1; i >= 0; i--) begin
            prod = den << i;
            if (num >= prod) begin
                num = num - prod;
                t = t | (1 << i);
            end
        end

        // Apply the sign
        calc_t_result = sign ? -t : t;
    end

    // interpolate logic
    logic signed [31:0] diff;
    logic signed [63:0] mult_result;

    always_comb begin
        diff = interp_v2 - interp_v1;
        mult_result = (diff * interp_t) >>> FIXED_POINT_SHIFT;
        interp_result = interp_v1 + mult_result[31:0];
    end

endmodule
