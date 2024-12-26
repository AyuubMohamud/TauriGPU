module intersection #(
    // 1 sign + 11 int + 12 frac = 24 bits total
    parameter WIDTH = 24  
)(
    input  logic                    clk_i,
    input  logic                    start_i,
    
    // Line segment endpoints (v1 to v2), each in 12.12 fixed point
    input  logic signed [WIDTH-1:0] v1_x,
    input  logic signed [WIDTH-1:0] v1_y,
    input  logic signed [WIDTH-1:0] v1_z,
    input  logic signed [WIDTH-1:0] v1_w,
    input  logic signed [WIDTH-1:0] v2_x,
    input  logic signed [WIDTH-1:0] v2_y,
    input  logic signed [WIDTH-1:0] v2_z,
    input  logic signed [WIDTH-1:0] v2_w,
    
    // Plane coefficients (a,b,c,d), each in 12.12 fixed point
    input  logic signed [WIDTH-1:0] plane_a,
    input  logic signed [WIDTH-1:0] plane_b,
    input  logic signed [WIDTH-1:0] plane_c,
    input  logic signed [WIDTH-1:0] plane_d,
    
    // Intersection point output in 12.12 fixed point (on segment)
    output logic signed [WIDTH-1:0] intersect_x,
    output logic signed [WIDTH-1:0] intersect_y,
    output logic signed [WIDTH-1:0] intersect_z,
    output logic signed [WIDTH-1:0] intersect_w,
    
    output logic                    done_o
);

always_ff @(posedge clk_i) begin
    if (start_i) begin
        // 64-bit accumulators to avoid overflow
        logic signed [63:0] sum_v1, sum_diff;
        logic signed [63:0] num, den;
        logic signed [63:0] t_raw;      // t in Q12, before clamping
        logic signed [63:0] t_clamped;  // t in Q12, clamped to [0,1]

        // For reference: 1.0 in Q12 is 4096
        localparam logic signed [63:0] Q12_ZERO = 64'd0;
        localparam logic signed [63:0] Q12_ONE  = 64'd4096;  // (1 << 12)

        //==================================================
        // plane . v1  => (plane_a * v1_x + plane_b * v1_y + ...)
        // Each multiply is (12 frac + 12 frac) => 24 frac bits.
        // sum_v1 is thus effectively Q24 in 64-bit container.
        //==================================================
        sum_v1 = (plane_a * v1_x)
               + (plane_b * v1_y)
               + (plane_c * v1_z)
               + (plane_d * v1_w);

        // num = -(plane . v1)  => still Q24
        num = -sum_v1;

        //==================================================
        // plane . (v2 - v1)
        //==================================================
        sum_diff = (plane_a * (v2_x - v1_x))
                 + (plane_b * (v2_y - v1_y))
                 + (plane_c * (v2_z - v1_z))
                 + (plane_d * (v2_w - v1_w));
        den = sum_diff;  // Q24

        //==================================================
        // Compute t in Q12:
        //   t = (num << 12) / den
        // 
        // Here: num, den are Q24. So:
        //   (num << 12) => Q24 shifted left by 12 => Q36
        //   Q36 / Q24 => Q12 result
        //==================================================
        if (den == 0) begin
            // Degenerate: line parallel to plane => no intersection or infinite
            t_raw = 0;  
        end
        else begin
            t_raw = (num <<< 12) / den;  
        end

        // Clamp t to [0, 1] in Q12
        if (t_raw < Q12_ZERO) begin
            t_clamped = Q12_ZERO;  // intersection effectively at v1
        end
        else if (t_raw > Q12_ONE) begin
            t_clamped = Q12_ONE;   // intersection effectively at v2
        end
        else begin
            t_clamped = t_raw;
        end

        //========================================================
        // Intersection in 12.12 (clamped to segment):
        //   intersect = v1 + [t_clamped * (v2 - v1) >> 12]
        //
        // (v2 - v1) is Q12, t_clamped is Q12 => product Q24,
        // shift right by 12 => back to Q12
        //========================================================
        intersect_x <= v1_x + ((t_clamped * (v2_x - v1_x)) >>> 12);
        intersect_y <= v1_y + ((t_clamped * (v2_y - v1_y)) >>> 12);
        intersect_z <= v1_z + ((t_clamped * (v2_z - v1_z)) >>> 12);
        intersect_w <= v1_w + ((t_clamped * (v2_w - v1_w)) >>> 12);

        done_o <= 1'b1;
    end
    else begin
        done_o <= 1'b0;
    end
end

endmodule
