module intersection #(
    parameter WIDTH = 20  // 1 sign + 11 int + 8 frac = 20 bits, "12.8" format
)(
    input  logic                    clk_i,
    input  logic                    start_i,
    
    // Line segment endpoints (v1 to v2), each in 12.8 fixed point
    input  logic signed [WIDTH-1:0] v1_x,
    input  logic signed [WIDTH-1:0] v1_y,
    input  logic signed [WIDTH-1:0] v1_z,
    input  logic signed [WIDTH-1:0] v1_w,
    input  logic signed [WIDTH-1:0] v2_x,
    input  logic signed [WIDTH-1:0] v2_y,
    input  logic signed [WIDTH-1:0] v2_z,
    input  logic signed [WIDTH-1:0] v2_w,
    
    // Plane coefficients (a,b,c,d), each in 12.8 fixed point
    input  logic signed [WIDTH-1:0] plane_a,
    input  logic signed [WIDTH-1:0] plane_b,
    input  logic signed [WIDTH-1:0] plane_c,
    input  logic signed [WIDTH-1:0] plane_d,
    
    // Intersection point output in 12.8 fixed point (on segment)
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
        logic signed [63:0] t_raw;      // t in Q16, before clamping
        logic signed [63:0] t_clamped;  // t in Q16, clamped to [0,1]

        // For reference: 1.0 in Q16 is 65536
        localparam logic signed [63:0] Q16_ZERO = 64'd0;
        localparam logic signed [63:0] Q16_ONE  = 64'd65536;

        //====================
        //   plane . v1  (Q16)
        //====================
        sum_v1 = (plane_a * v1_x)
               + (plane_b * v1_y)
               + (plane_c * v1_z)
               + (plane_d * v1_w);

        // num = -(plane . v1)
        num = -sum_v1;  // Q16

        //==============================
        //   plane . (v2 - v1)  (Q16)
        //==============================
        sum_diff = (plane_a * (v2_x - v1_x))
                 + (plane_b * (v2_y - v1_y))
                 + (plane_c * (v2_z - v1_z))
                 + (plane_d * (v2_w - v1_w));
        den = sum_diff; // Q16

        //====================
        // Compute t = num / den in Q16
        // => t = (num << 16) / den
        //====================
        if (den == 0) begin
            // Degenerate: line parallel to plane => no intersection or infinite
            t_raw = 0;
        end
        else begin
            t_raw = (num <<< 16) / den;  
        end

        //====================
        // Clamp t to [0, 1] in Q16
        //====================
        if (t_raw < Q16_ZERO) begin
            t_clamped = Q16_ZERO;  // means intersection is effectively at v1
        end
        else if (t_raw > Q16_ONE) begin
            t_clamped = Q16_ONE;   // means intersection is effectively at v2
        end
        else begin
            t_clamped = t_raw;
        end

        //=========================================
        // Intersection in Q8 (clamped to segment):
        //   intersect = v1 + [t_clamped * (v2 - v1) >> 16]
        //=========================================
        intersect_x <= v1_x + ((t_clamped * (v2_x - v1_x)) >>> 16);
        intersect_y <= v1_y + ((t_clamped * (v2_y - v1_y)) >>> 16);
        intersect_z <= v1_z + ((t_clamped * (v2_z - v1_z)) >>> 16);
        intersect_w <= v1_w + ((t_clamped * (v2_w - v1_w)) >>> 16);

        done_o <= 1'b1;
    end
    else begin
        done_o <= 1'b0;
    end
end

endmodule
