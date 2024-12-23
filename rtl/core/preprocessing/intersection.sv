module intersection #(
    parameter WIDTH = 16  // 12.4 format: 1 sign + 11 int + 4 frac = 16 bits
)(
    input  logic                    clk_i,
    input  logic                    start_i,
    
    // Line segment endpoints (v1 to v2)
    input  logic signed [WIDTH-1:0] v1_x,
    input  logic signed [WIDTH-1:0] v1_y,
    input  logic signed [WIDTH-1:0] v1_z,
    input  logic signed [WIDTH-1:0] v1_w,
    input  logic signed [WIDTH-1:0] v2_x,
    input  logic signed [WIDTH-1:0] v2_y,
    input  logic signed [WIDTH-1:0] v2_z,
    input  logic signed [WIDTH-1:0] v2_w,
    
    // Plane coefficients
    input  logic signed [WIDTH-1:0] plane_a,
    input  logic signed [WIDTH-1:0] plane_b,
    input  logic signed [WIDTH-1:0] plane_c,
    input  logic signed [WIDTH-1:0] plane_d,
    
    // Intersection point output
    output logic signed [WIDTH-1:0] intersect_x,
    output logic signed [WIDTH-1:0] intersect_y,
    output logic signed [WIDTH-1:0] intersect_z,
    output logic signed [WIDTH-1:0] intersect_w,
    
    output logic                    done_o
);

always_ff @(posedge clk_i) begin
    if (start_i) begin
        // Use 32 bits for intermediate calculations (16.16 format)
        logic signed [31:0] num;
        logic signed [31:0] den;
        logic signed [31:0] t;
        
        // Calculate numerator, scaling up by 16 bits
        // Note: When multiplying two 12.4 numbers, result is 24.8 format
        num = (-($signed(plane_a)*$signed(v1_x) + 
                 $signed(plane_b)*$signed(v1_y) + 
                 $signed(plane_c)*$signed(v1_z) + 
                 $signed(plane_d)*$signed(v1_w))) << 8; // Scale from 24.8 to 16.16
                 
        // Calculate denominator (24.8 format initially)
        den = ($signed(plane_a)*$signed(v2_x - v1_x) + 
               $signed(plane_b)*$signed(v2_y - v1_y) + 
               $signed(plane_c)*$signed(v2_z - v1_z) + 
               $signed(plane_d)*$signed(v2_w - v1_w));
               
        // Scale denominator to match numerator's 16.16 format
        den = den << 8;
        
        // Compute t while maintaining fixed-point precision (result in 16.16)
        t = (den == 0) ? 0 : (num / den);
        
        // Calculate intersections
        // When multiplying t (16.16) with v2-v1 (12.4), result needs to be shifted right by 16
        // to get back to 12.4 format
        intersect_x <= v1_x + ((t * $signed(v2_x - v1_x)) >>> 16);
        intersect_y <= v1_y + ((t * $signed(v2_y - v1_y)) >>> 16);
        intersect_z <= v1_z + ((t * $signed(v2_z - v1_z)) >>> 16);
        intersect_w <= v1_w + ((t * $signed(v2_w - v1_w)) >>> 16);

        done_o <= 1'b1;
    end else begin
        done_o <= 1'b0;
    end
end

endmodule
