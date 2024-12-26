module clipper #(
    parameter WIDTH = 24 // 12.12 
)(
    input wire clk_i,
    input logic start_i,
    input logic reset_n,

    // Triangle vertices
    input logic signed [WIDTH-1:0] v0_x_i, v0_y_i, v0_z_i, v0_w_i,
    input logic signed [WIDTH-1:0] v1_x_i, v1_y_i, v1_z_i, v1_w_i,
    input logic signed [WIDTH-1:0] v2_x_i, v2_y_i, v2_z_i, v2_w_i,

    // Frustum plane coefficients
    // Plane equation: N . P + d = 0, equivalent to (A,B,C,D) coefficients from the equation Ax + By + Cz + D = 0
    input logic signed [WIDTH-1:0] plane_normal_x_i, plane_normal_y_i, plane_normal_z_i, plane_offset_i, 

    // Output vertices
        // Two triangles because there is a potential of internal quad split
    output logic signed [WIDTH-1:0] clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
    output logic signed [WIDTH-1:0] clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
    output logic signed [WIDTH-1:0] clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o,
    output logic signed [WIDTH-1:0] clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
    output logic signed [WIDTH-1:0] clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
    output logic signed [WIDTH-1:0] clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o,
    
    output logic done_o,
    output logic valid_o,
    
    // After clipping, there can be 1 or 2 triangles (assuming triangles only cut through one plane)
    output logic [1:0] num_triangles_o 
);

    // Signals for classification
    logic [2:0] vertex_inside; // XXX <-- which vertices are inside the frustum
    logic [1:0] vertex_inside_count; // Count of how many vertices are inside the frustum
    logic signed [63:0] dot_product_v0, dot_product_v1, dot_product_v2;

    // Signals for clipping
    logic [WIDTH-1:0] intersect1_x, intersect1_y, intersect1_z, intersect1_w;
    logic [WIDTH-1:0] intersect2_x, intersect2_y, intersect2_z, intersect2_w;

    // Signals for intersection
    logic intersect_calc_done1, intersect_calc_done2;

    // States
    typedef enum logic [2:0] {
        IDLE,
        CLASSIFY,
        INTERSECT,
        CLIP,
        DONE
    } state_t;

    state_t curr_state, next_state;

    // State machine
    always_ff @(posedge clk_i or negedge reset_n) begin
        if (!reset_n) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    logic intersect_signal;

    always_comb begin
        next_state = curr_state;
        intersect_signal = 0;

        case (curr_state)
            IDLE: begin
                if (start_i) begin
                    next_state = CLASSIFY;
                end
            end
            CLASSIFY: begin
                if (classification_done) begin
                    next_state = INTERSECT;
                end
            end
            INTERSECT: begin
                intersect_signal = 1;
                if (intersect_calc_done1 && intersect_calc_done2) begin
                    next_state = CLIP;
                end
            end
            CLIP: next_state = DONE;
            DONE: begin
                if (!start_i) begin
                    next_state = IDLE;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    assign done_o = (curr_state == DONE);

    intersection intersection1 (
        .clk_i(clk_i),
        .start_i(intersect_signal),
        .v1_x(v1_x_i),
        .v1_y(v1_y_i),
        .v1_z(v1_z_i),
        .v1_w(v1_w_i),
        .v2_x(v2_x_i),
        .v2_y(v2_y_i),
        .v2_z(v2_z_i),
        .v2_w(v2_w_i),
        .plane_a(plane_normal_x_i),
        .plane_b(plane_normal_y_i),
        .plane_c(plane_normal_z_i),
        .plane_d(plane_offset_i),
        .intersect_x(intersect1_x),
        .intersect_y(intersect1_y),
        .intersect_z(intersect1_z),
        .intersect_w(intersect1_w),
        .done_o(intersect_calc_done1)
    );

    intersection intersection2 (
        .clk_i(clk_i),
        .start_i(intersect_signal),
        .v1_x(v2_x_i),
        .v1_y(v2_y_i),
        .v1_z(v2_z_i),
        .v1_w(v2_w_i),
        .v2_x(v0_x_i),
        .v2_y(v0_y_i),
        .v2_z(v0_z_i),
        .v2_w(v0_w_i),
        .plane_a(plane_normal_x_i),
        .plane_b(plane_normal_y_i),
        .plane_c(plane_normal_z_i),
        .plane_d(plane_offset_i),
        .intersect_x(intersect2_x),
        .intersect_y(intersect2_y),
        .intersect_z(intersect2_z),
        .intersect_w(intersect2_w),
        .done_o(intersect_calc_done2)
    );

    // Classifying stage

    logic dot_products_done;
    logic classification_done;

    always_ff @(posedge clk_i) begin

        // Classify stage 1

        if (curr_state == CLASSIFY && !dot_products_done) begin
            // Calculate dot product of vertex[0] with plane normal
            dot_product_v0 <= 
                (($signed(v0_x_i) * $signed(plane_normal_x_i)) + 
                ($signed(v0_y_i) * $signed(plane_normal_y_i)) + 
                ($signed(v0_z_i) * $signed(plane_normal_z_i)) + 
                ($signed(v0_w_i) * $signed(plane_offset_i))) >>> 12;
            
            dot_product_v1 <= 
                (($signed(v1_x_i) * $signed(plane_normal_x_i)) + 
                ($signed(v1_y_i) * $signed(plane_normal_y_i)) + 
                ($signed(v1_z_i) * $signed(plane_normal_z_i)) + 
                ($signed(v1_w_i) * $signed(plane_offset_i))) >>> 12;

            dot_product_v2 <= 
                (($signed(v2_x_i) * $signed(plane_normal_x_i)) + 
                ($signed(v2_y_i) * $signed(plane_normal_y_i)) + 
                ($signed(v2_z_i) * $signed(plane_normal_z_i)) + 
                ($signed(v2_w_i) * $signed(plane_offset_i))) >>> 12;

            dot_products_done <= 1;
        end else if (curr_state != CLASSIFY) begin
            dot_products_done <= 0;
        end

        // Classify stage 2

        if (curr_state == CLASSIFY && dot_products_done) begin
            vertex_inside[0] <= (dot_product_v0 >= 0);
            vertex_inside[1] <= (dot_product_v1 >= 0);
            vertex_inside[2] <= (dot_product_v2 >= 0);
            vertex_inside_count <= vertex_inside[0] + vertex_inside[1] + vertex_inside[2];
            classification_done <= 1;
        end else if (curr_state != CLASSIFY) begin
            classification_done <= 0;
        end

    end

    // Clipping stage 
    // ** New vertices follow clockwise winding order
    always_ff @(posedge clk_i) begin
        if (curr_state == CLIP) begin
            case (vertex_inside_count)
                2'd0: begin
                    // All vertices are outside, triangle culled
                    valid_o <= 0;
                    num_triangles_o <= 0;
                end
                2'd1: begin
                    // One vertex is inside, one clipped triangle output
                    valid_o <= 1;
                    num_triangles_o <= 1;
                    if (vertex_inside[0]) begin
                        // v0 is inside, v1 and v2 are outside
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end else if (vertex_inside[1]) begin
                        // v1 is inside, v0 and v2 are outside
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v1_x_i, v1_y_i, v1_z_i, v1_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end else begin
                        // v2 is inside, v0 and v1 are outside
                        // Clip v0 and v1 against the frustum
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end
                end
                2'd2: begin
                    // Two vertices are inside, internal quad split into two triangles
                    // ** Intersection order must be followed:
                    // ** If v2 is inside, then v0-v1 is the first intersection
                    // ** If v2 is outside, then v1-v2 is the first intersection
                    // ** The triangle is always made using intersection 1 to opposite vertex as the edge
                    valid_o <= 1;
                    num_triangles_o <= 2;
                    if (!vertex_inside[0]) begin
                        // v0 is outside, v1 and v2 are inside
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {v1_x_i, v1_y_i, v1_z_i, v1_w_i};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};

                        {clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};
                        {clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};

                    end else if (!vertex_inside[1]) begin
                        // v1 is outside, v0 and v2 are inside
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};

                        {clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};
                        {clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                        
                    end else begin
                        // v2 is outside, v0 and v1 are inside
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {v1_x_i, v1_y_i, v1_z_i, v1_w_i};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};

                        {clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                        {clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end
                end 
                2'd3: begin
                    // All vertices are inside, no clipping required
                    valid_o <= 1;
                    num_triangles_o <= 1;
                    {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                    {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {v1_x_i, v1_y_i, v1_z_i, v1_w_i};
                    {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};
                end
            endcase
        end
    end

endmodule
