module intersection_b #(
    parameter VERTEX_WIDTH = 16,     // 12.4 format
    parameter FRAC_BITS = 4        
)(
    input  wire clk_i,
    input  wire start_i,

    // Vertex 1 (inside vertex)
    input  logic signed [VERTEX_WIDTH-1:0] v1_x,
    input  logic signed [VERTEX_WIDTH-1:0] v1_y,
    input  logic signed [VERTEX_WIDTH-1:0] v1_z,
    input  logic signed [VERTEX_WIDTH-1:0] v1_w,

    // Vertex 2 (outside vertex)
    input  logic signed [VERTEX_WIDTH-1:0] v2_x,
    input  logic signed [VERTEX_WIDTH-1:0] v2_y,
    input  logic signed [VERTEX_WIDTH-1:0] v2_z,
    input  logic signed [VERTEX_WIDTH-1:0] v2_w,

    // Plane equation coefficients
    input  logic signed [VERTEX_WIDTH-1:0] plane_a,
    input  logic signed [VERTEX_WIDTH-1:0] plane_b,
    input  logic signed [VERTEX_WIDTH-1:0] plane_c,
    input  logic signed [VERTEX_WIDTH-1:0] plane_d,

    // Intersection point outputs
    output logic signed [VERTEX_WIDTH-1:0] intersect_x,
    output logic signed [VERTEX_WIDTH-1:0] intersect_y,
    output logic signed [VERTEX_WIDTH-1:0] intersect_z,
    output logic signed [VERTEX_WIDTH-1:0] intersect_w,

    output logic done_o
);

    // Internal signals for intermediate calculations
    logic signed [2*VERTEX_WIDTH-1:0] num;        // For numerator calculation
    logic signed [2*VERTEX_WIDTH-1:0] den;        // For denominator calculation
    logic signed [2*VERTEX_WIDTH-1:0] t;          // For t parameter
    logic signed [2*VERTEX_WIDTH-1:0] mul_temp;   // For intermediate multiplications

    // Pipeline registers for intermediate results
    logic signed [VERTEX_WIDTH-1:0] dx, dy, dz, dw;
    logic signed [VERTEX_WIDTH-1:0] t_scaled;

    // State counter to track pipeline stages
    logic [2:0] state_counter;

    always_ff @(posedge clk_i) begin
        if (start_i) begin
            // Reset state and done signal
            state_counter <= 3'd0;
            done_o <= 1'b0;

            // Calculate deltas
            dx <= v2_x - v1_x;
            dy <= v2_y - v1_y;
            dz <= v2_z - v1_z;
            dw <= v2_w - v1_w;

            // Calculate numerator (24.8 format initially)
            num = (-($signed(plane_a)*$signed(v1_x) + 
                    $signed(plane_b)*$signed(v1_y) + 
                    $signed(plane_c)*$signed(v1_z) + 
                    $signed(plane_d)*$signed(v1_w)));
                    
            // Calculate denominator (24.8 format initially)
            den = ($signed(plane_a)*$signed(v2_x - v1_x) + 
                  $signed(plane_b)*$signed(v2_y - v1_y) + 
                  $signed(plane_c)*$signed(v2_z - v1_z) + 
                  $signed(plane_d)*$signed(v2_w - v1_w));
                  
            // Scale both to match formats (16.16)
            num = num << 8;  // Scale up by 8 more bits
            den = den << 8;  // Scale up by 8 more bits

            // Calculate t while maintaining precision
            t = (den == 0) ? 0 : (num / den);
            
            // Scale t back to 12.4 format
            t_scaled <= t[VERTEX_WIDTH-1 + FRAC_BITS : FRAC_BITS];
            
        end else if (state_counter == 3'd0) begin
            // Calculate X intersection
            mul_temp = $signed(t_scaled) * $signed(dx);
            intersect_x <= v1_x + mul_temp[VERTEX_WIDTH-1 + FRAC_BITS : FRAC_BITS];
            state_counter <= state_counter + 1;

        end else if (state_counter == 3'd1) begin
            // Calculate Y intersection
            mul_temp = $signed(t_scaled) * $signed(dy);
            intersect_y <= v1_y + mul_temp[VERTEX_WIDTH-1 + FRAC_BITS : FRAC_BITS];
            state_counter <= state_counter + 1;

        end else if (state_counter == 3'd2) begin
            // Calculate Z intersection
            mul_temp = $signed(t_scaled) * $signed(dz);
            intersect_z <= v1_z + mul_temp[VERTEX_WIDTH-1 + FRAC_BITS : FRAC_BITS];
            state_counter <= state_counter + 1;

        end else if (state_counter == 3'd3) begin
            // Calculate W intersection
            mul_temp = $signed(t_scaled) * $signed(dw);
            intersect_w <= v1_w + mul_temp[VERTEX_WIDTH-1 + FRAC_BITS : FRAC_BITS];
            state_counter <= state_counter + 1;
            done_o <= 1'b1;

        end else if (state_counter == 3'd4) begin
            // Hold done signal for one cycle then clear it
            done_o <= 1'b0;
            state_counter <= state_counter + 1;
        end
    end

endmodule
