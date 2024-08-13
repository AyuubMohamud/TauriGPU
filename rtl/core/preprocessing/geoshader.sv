module geoshader #(
    parameter VERTEX_WIDTH = 32,
    parameter FRUSTUM_WIDTH = 32
)(
    input wire clk_i,
    input logic start_i,

    // Vertex shader output
    input logic [VERTEX_WIDTH-1:0] v0_x_i, v0_y_i, v0_z_i, v0_w_i,
    input logic [VERTEX_WIDTH-1:0] v1_x_i, v1_y_i, v1_z_i, v1_w_i,
    input logic [VERTEX_WIDTH-1:0] v2_x_i, v2_y_i, v2_z_i, v2_w_i,

    // Frustum plane coefficients
    input logic signed [FRUSTUM_WIDTH-1:0] left_plane_normal_x_i, left_plane_normal_y_i, left_plane_normal_z_i, left_plane_offset_i,
    input logic signed [FRUSTUM_WIDTH-1:0] right_plane_normal_x_i, right_plane_normal_y_i, right_plane_normal_z_i, right_plane_offset_i,
    input logic signed [FRUSTUM_WIDTH-1:0] top_plane_normal_x_i, top_plane_normal_y_i, top_plane_normal_z_i, top_plane_offset_i,
    input logic signed [FRUSTUM_WIDTH-1:0] bottom_plane_normal_x_i, bottom_plane_normal_y_i, bottom_plane_normal_z_i, bottom_plane_offset_i,
    input logic signed [FRUSTUM_WIDTH-1:0] near_plane_normal_x_i, near_plane_normal_y_i, near_plane_normal_z_i, near_plane_offset_i,
    input logic signed [FRUSTUM_WIDTH-1:0] far_plane_normal_x_i, far_plane_normal_y_i, far_plane_normal_z_i, far_plane_offset_i,

    // Output to rasteriser
        // Two triangles because there is a potential of internal quad split
    output logic [VERTEX_WIDTH-1:0] clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
    output logic [VERTEX_WIDTH-1:0] clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
    output logic [VERTEX_WIDTH-1:0] clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o,
    
    output logic [VERTEX_WIDTH-1:0] clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
    output logic [VERTEX_WIDTH-1:0] clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
    output logic [VERTEX_WIDTH-1:0] clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o,

    output logic done_o,
    // output logic valid_o,
    
    // After clipping, there can be 1 or 2 triangles (assuming triangles only cut through one plane)
    output logic [1:0] num_triangles_o 
);

    // Define constants for fixed point arithmetic
    localparam FIXED_POINT_SHIFT = 8;
    localparam FIXED_POINT_ONE = 1 << FIXED_POINT_SHIFT;

    // Signals for classification
    logic cull;
    logic [2:0] vertex_inside; // XXX <-- which vertices are inside the frustum
    logic [1:0] vertex_inside_count; // Count of how many vertices are inside the frustum

    // States
    typedef enum logic [2:0] {
        IDLE,
        CLASSIFY,
        CLIP,
        OUTPUT,
        DONE
    } state_t;

    state_t curr_state, next_state;

    // Clipper helper module
    clipper_helper helper(
        .clk_i(clk_i),
        // other ports
        // TODO: FIX
    );

    // State machine
    always_ff @(posedge clk_i) begin
        if (start_i) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: if (start_i) next_state = CLASSIFY;
            // If triangle is classified as culled, skip to DONE state
            // Either culled or clipped
            CLASSIFY: begin 
                if (cull) next_state = DONE; // TODO: Check if this has timing issues
                else next_state = CLIP;
            end; 
            CLIP: next_state = DONE;
            DONE: next_state = IDLE;
        endcase
    end

    // Classifying stage
    always_ff @(posedge clk_i) begin

        if (curr_state == CLASSIFY) begin

            // Check if all vertices are outside any of the frustum planes

            logic signed [FRUSTUM_WIDTH-1:0] d0_left, d1_left, d2_left;
            logic signed [FRUSTUM_WIDTH-1:0] d0_right, d1_right, d2_right;
            logic signed [FRUSTUM_WIDTH-1:0] d0_top, d1_top, d2_top;
            logic signed [FRUSTUM_WIDTH-1:0] d0_bottom, d1_bottom, d2_bottom;
            logic signed [FRUSTUM_WIDTH-1:0] d0_near, d1_near, d2_near;
            logic signed [FRUSTUM_WIDTH-1:0] d0_far, d1_far, d2_far;

            d0_left = left_plane_normal_x_i * v0_x_i + left_plane_normal_y_i * v0_y_i + left_plane_normal_z_i * v0_z_i + left_plane_offset_i;
            d1_left = left_plane_normal_x_i * v1_x_i + left_plane_normal_y_i * v1_y_i + left_plane_normal_z_i * v1_z_i + left_plane_offset_i;
            d2_left = left_plane_normal_x_i * v2_x_i + left_plane_normal_y_i * v2_y_i + left_plane_normal_z_i * v2_z_i + left_plane_offset_i;
            
            d0_right = right_plane_normal_x_i * v0_x_i + right_plane_normal_y_i * v0_y_i + right_plane_normal_z_i * v0_z_i + right_plane_offset_i;
            d1_right = right_plane_normal_x_i * v1_x_i + right_plane_normal_y_i * v1_y_i + right_plane_normal_z_i * v1_z_i + right_plane_offset_i;
            d2_right = right_plane_normal_x_i * v2_x_i + right_plane_normal_y_i * v2_y_i + right_plane_normal_z_i * v2_z_i + right_plane_offset_i;

            d0_top = top_plane_normal_x_i * v0_x_i + top_plane_normal_y_i * v0_y_i + top_plane_normal_z_i * v0_z_i + top_plane_offset_i;
            d1_top = top_plane_normal_x_i * v1_x_i + top_plane_normal_y_i * v1_y_i + top_plane_normal_z_i * v1_z_i + top_plane_offset_i;
            d2_top = top_plane_normal_x_i * v2_x_i + top_plane_normal_y_i * v2_y_i + top_plane_normal_z_i * v2_z_i + top_plane_offset_i;
            
            d0_bottom = bottom_plane_normal_x_i * v0_x_i + bottom_plane_normal_y_i * v0_y_i + bottom_plane_normal_z_i * v0_z_i + bottom_plane_offset_i;
            d1_bottom = bottom_plane_normal_x_i * v1_x_i + bottom_plane_normal_y_i * v1_y_i + bottom_plane_normal_z_i * v1_z_i + bottom_plane_offset_i;
            d2_bottom = bottom_plane_normal_x_i * v2_x_i + bottom_plane_normal_y_i * v2_y_i + bottom_plane_normal_z_i * v2_z_i + bottom_plane_offset_i;
            
            d0_near = near_plane_normal_x_i * v0_x_i + near_plane_normal_y_i * v0_y_i + near_plane_normal_z_i * v0_z_i + near_plane_offset_i;
            d1_near = near_plane_normal_x_i * v1_x_i + near_plane_normal_y_i * v1_y_i + near_plane_normal_z_i * v1_z_i + near_plane_offset_i;
            d2_near = near_plane_normal_x_i * v2_x_i + near_plane_normal_y_i * v2_y_i + near_plane_normal_z_i * v2_z_i + near_plane_offset_i;

            d0_far = far_plane_normal_x_i * v0_x_i + far_plane_normal_y_i * v0_y_i + far_plane_normal_z_i * v0_z_i + far_plane_offset_i;
            d1_far = far_plane_normal_x_i * v1_x_i + far_plane_normal_y_i * v1_y_i + far_plane_normal_z_i * v1_z_i + far_plane_offset_i;
            d2_far = far_plane_normal_x_i * v2_x_i + far_plane_normal_y_i * v2_y_i + far_plane_normal_z_i * v2_z_i + far_plane_offset_i;

            // Cull the triangle if all three vertices are outside of the frustum, and I don't care if the triangle slices through the frustum
            
            cull = (d0_left < 0 && d1_left < 0 && d2_left < 0) ||
                (d0_right < 0 && d1_right < 0 && d2_right < 0) ||
                (d0_top < 0 && d1_top < 0 && d2_top < 0) ||
                (d0_bottom < 0 && d1_bottom < 0 && d2_bottom < 0) ||
                (d0_near < 0 && d1_near < 0 && d2_near < 0) ||
                (d0_far < 0 && d1_far < 0 && d2_far < 0);
            
            // Check all vertices and classify them as inside or outside the frustum

            // TODO: On frustum edge counts as inside frustum

            // This is a simplified version, you'll need to check against all planes 
                // TODO: FIX
            vertex_inside[0] <= (v0_x_i >= -v0_w_i) && (v0_x_i <= v0_w_i) && 
                (v0_y_i >= -v0_w_i) && (v0_y_i <= v0_w_i) && 
                (v0_z_i >= 0) && (v0_z_i <= v0_w_i);
            vertex_inside[1] <= (v1_x_i >= -v1_w_i) && (v1_x_i <= v1_w_i) && 
                (v1_y_i >= -v1_w_i) && (v1_y_i <= v1_w_i) && 
                (v1_z_i >= 0) && (v1_z_i <= v1_w_i);
            vertex_inside[2] <= (v2_x_i >= -v2_w_i) && (v2_x_i <= v2_w_i) && 
                (v2_y_i >= -v2_w_i) && (v2_y_i <= v2_w_i) && 
                (v2_z_i >= 0) && (v2_z_i <= v2_w_i);
            
            vertex_inside_count <= vertex_inside[0] + vertex_inside[1] + vertex_inside[2];
            
        end
    end

    // Clipping stage
    always_ff @(posedge clk_i) begin
        if (curr_state == CLIP) begin

            // Case 4: One vertex in, two vertex out - don't care about external quad, keep internal triangle
        
            // Other cases: I can't give a fuck

            case (vertex_inside_count)
                2'd0: 
                    // Case: All vertices are inside the frustum - no clipping required
                    num_triangles_o <= 1;
                    clipped_v0_x_o <= v0_x_i;
                    clipped_v0_y_o <= v0_y_i;
                    clipped_v0_z_o <= v0_z_i;
                    clipped_v0_w_o <= v0_w_i;

                    clipped_v1_x_o <= v1_x_i;
                    clipped_v1_y_o <= v1_y_i;
                    clipped_v1_z_o <= v1_z_i;
                    clipped_v1_w_o <= v1_w_i;

                    clipped_v2_x_o <= v2_x_i;
                    clipped_v2_y_o <= v2_y_i;
                    clipped_v2_z_o <= v2_z_i;
                    clipped_v2_w_o <= v2_w_i;
                2'd1:
                    // Case: One vertex is 

                    // Case 2: One vertex in (on edge)


                    // Case 2: One vertex in, one vertex out, one vertex on frustum plane edge - split the triangle into two triangles, keep internal triangle


                    // Case 3: One vertex in, two vertex out - don't care about external quad, keep internal triangle


                2'd2: 

                    // Case 4: Two vertex in, one vertex out - split internal quad into two triangles (intersection point to opposite internal edge)

                    num_triangles_o <= 

                2'd3:

            endcase

        end
    end

    // Done stage
    always_ff @(posedge clk_i) begin
        done_o <= (curr_state == DONE) ? 1'b1 : 1'b0;
    end

endmodule
