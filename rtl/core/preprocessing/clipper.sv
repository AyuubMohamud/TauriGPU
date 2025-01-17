module clipper #(parameter WIDTH = 24)(
    input wire clk_i,
    input  logic start_i,
    input  logic reset_n,

    input  logic signed [WIDTH-1:0] v0_x_i, v0_y_i, v0_z_i, v0_w_i,
    input  logic signed [WIDTH-1:0] v1_x_i, v1_y_i, v1_z_i, v1_w_i,
    input  logic signed [WIDTH-1:0] v2_x_i, v2_y_i, v2_z_i, v2_w_i,

    input  logic signed [WIDTH-1:0] plane_normal_x_i,
    input  logic signed [WIDTH-1:0] plane_normal_y_i,
    input  logic signed [WIDTH-1:0] plane_normal_z_i,
    input  logic signed [WIDTH-1:0] plane_offset_i,

    output logic signed [WIDTH-1:0] clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
    output logic signed [WIDTH-1:0] clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
    output logic signed [WIDTH-1:0] clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o,
    output logic signed [WIDTH-1:0] clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
    output logic signed [WIDTH-1:0] clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
    output logic signed [WIDTH-1:0] clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o,

    output logic done_o,
    output logic valid_o,
    output logic [1:0] num_triangles_o
);

    logic [2:0]  vertex_inside;
    logic [1:0]  vertex_inside_count;
    logic signed [63:0] dot_product_v0, dot_product_v1, dot_product_v2;

    logic [WIDTH-1:0] intersect1_x, intersect1_y, intersect1_z, intersect1_w;
    logic [WIDTH-1:0] intersect2_x, intersect2_y, intersect2_z, intersect2_w;
    logic intersect_calc_done1, intersect_calc_done2;

    typedef enum logic [2:0] {
        IDLE,
        CLASSIFY,
        INTERSECT,
        CLIP,
        DONE
    } state_t;

    state_t curr_state, next_state;

    always_ff @(posedge clk_i or negedge reset_n) begin
        if (!reset_n)
            curr_state <= IDLE;
        else
            curr_state <= next_state;
    end

    logic intersect_signal;

    always_comb begin
        next_state = curr_state;
        intersect_signal = 0;
        case (curr_state)
            IDLE: begin
                if (start_i) next_state = CLASSIFY;
            end
            CLASSIFY: begin
                if (classification_done) next_state = INTERSECT;
            end
            INTERSECT: begin
                intersect_signal = 1;
                if (intersect_calc_done1 && intersect_calc_done2)
                    next_state = CLIP;
            end
            CLIP: begin
                next_state = DONE;
            end
            DONE: begin
                if (!start_i) next_state = IDLE;
            end
        endcase
    end

    assign done_o = (curr_state == DONE);

    logic [WIDTH-1:0] v1_x_int1, v1_y_int1, v1_z_int1, v1_w_int1;
    logic [WIDTH-1:0] v2_x_int1, v2_y_int1, v2_z_int1, v2_w_int1;
    logic [WIDTH-1:0] v1_x_int2, v1_y_int2, v1_z_int2, v1_w_int2;
    logic [WIDTH-1:0] v2_x_int2, v2_y_int2, v2_z_int2, v2_w_int2;

    always_comb begin
        if (vertex_inside_count == 2'd2) begin
            if (!vertex_inside[0]) begin
                v1_x_int1 = v1_x_i;
                v1_y_int1 = v1_y_i;
                v1_z_int1 = v1_z_i;
                v1_w_int1 = v1_w_i;
                v2_x_int1 = v0_x_i;
                v2_y_int1 = v0_y_i;
                v2_z_int1 = v0_z_i;
                v2_w_int1 = v0_w_i;
                v1_x_int2 = v2_x_i;
                v1_y_int2 = v2_y_i;
                v1_z_int2 = v2_z_i;
                v1_w_int2 = v2_w_i;
                v2_x_int2 = v0_x_i;
                v2_y_int2 = v0_y_i;
                v2_z_int2 = v0_z_i;
                v2_w_int2 = v0_w_i;
            end
            else if (!vertex_inside[1]) begin
                v1_x_int1 = v1_x_i;
                v1_y_int1 = v1_y_i;
                v1_z_int1 = v1_z_i;
                v1_w_int1 = v1_w_i;
                v2_x_int1 = v2_x_i;
                v2_y_int1 = v2_y_i;
                v2_z_int1 = v2_z_i;
                v2_w_int1 = v2_w_i;
                v1_x_int2 = v1_x_i;
                v1_y_int2 = v1_y_i;
                v1_z_int2 = v1_z_i;
                v1_w_int2 = v1_w_i;
                v2_x_int2 = v0_x_i;
                v2_y_int2 = v0_y_i;
                v2_z_int2 = v0_z_i;
                v2_w_int2 = v0_w_i;
            end
            else begin
                v1_x_int1 = v0_x_i;
                v1_y_int1 = v0_y_i;
                v1_z_int1 = v0_z_i;
                v1_w_int1 = v0_w_i;
                v2_x_int1 = v2_x_i;
                v2_y_int1 = v2_y_i;
                v2_z_int1 = v2_z_i;
                v2_w_int1 = v2_w_i;
                v1_x_int2 = v1_x_i;
                v1_y_int2 = v1_y_i;
                v1_z_int2 = v1_z_i;
                v1_w_int2 = v1_w_i;
                v2_x_int2 = v2_x_i;
                v2_y_int2 = v2_y_i;
                v2_z_int2 = v2_z_i;
                v2_w_int2 = v2_w_i;
            end
        end
        else begin
            v1_x_int1 = vertex_inside[0] ? v0_x_i : (vertex_inside[1] ? v1_x_i : v2_x_i);
            v1_y_int1 = vertex_inside[0] ? v0_y_i : (vertex_inside[1] ? v1_y_i : v2_y_i);
            v1_z_int1 = vertex_inside[0] ? v0_z_i : (vertex_inside[1] ? v1_z_i : v2_z_i);
            v1_w_int1 = vertex_inside[0] ? v0_w_i : (vertex_inside[1] ? v1_w_i : v2_w_i);
            v2_x_int1 = vertex_inside[0] ? v1_x_i : (vertex_inside[1] ? v2_x_i : v0_x_i);
            v2_y_int1 = vertex_inside[0] ? v1_y_i : (vertex_inside[1] ? v2_y_i : v0_y_i);
            v2_z_int1 = vertex_inside[0] ? v1_z_i : (vertex_inside[1] ? v2_z_i : v0_z_i);
            v2_w_int1 = vertex_inside[0] ? v1_w_i : (vertex_inside[1] ? v2_w_i : v0_w_i);
            v1_x_int2 = vertex_inside[0] ? v0_x_i : (vertex_inside[1] ? v1_x_i : v2_x_i);
            v1_y_int2 = vertex_inside[0] ? v0_y_i : (vertex_inside[1] ? v1_y_i : v2_y_i);
            v1_z_int2 = vertex_inside[0] ? v0_z_i : (vertex_inside[1] ? v1_z_i : v2_z_i);
            v1_w_int2 = vertex_inside[0] ? v0_w_i : (vertex_inside[1] ? v1_w_i : v2_w_i);
            v2_x_int2 = vertex_inside[0] ? v2_x_i : (vertex_inside[1] ? v0_x_i : v1_x_i);
            v2_y_int2 = vertex_inside[0] ? v2_y_i : (vertex_inside[1] ? v0_y_i : v1_y_i);
            v2_z_int2 = vertex_inside[0] ? v2_z_i : (vertex_inside[1] ? v0_z_i : v1_z_i);
            v2_w_int2 = vertex_inside[0] ? v2_w_i : (vertex_inside[1] ? v0_w_i : v1_w_i);
        end
    end

    intersection intersection1 (
        .clk_i     (clk_i),
        .start_i   (intersect_signal),
        .v1_x      (v1_x_int1),
        .v1_y      (v1_y_int1),
        .v1_z      (v1_z_int1),
        .v1_w      (v1_w_int1),
        .v2_x      (v2_x_int1),
        .v2_y      (v2_y_int1),
        .v2_z      (v2_z_int1),
        .v2_w      (v2_w_int1),
        .plane_a   (plane_normal_x_i),
        .plane_b   (plane_normal_y_i),
        .plane_c   (plane_normal_z_i),
        .plane_d   (plane_offset_i),
        .intersect_x (intersect1_x),
        .intersect_y (intersect1_y),
        .intersect_z (intersect1_z),
        .intersect_w (intersect1_w),
        .done_o    (intersect_calc_done1)
    );

    intersection intersection2 (
        .clk_i     (clk_i),
        .start_i   (intersect_signal),
        .v1_x      (v1_x_int2),
        .v1_y      (v1_y_int2),
        .v1_z      (v1_z_int2),
        .v1_w      (v1_w_int2),
        .v2_x      (v2_x_int2),
        .v2_y      (v2_y_int2),
        .v2_z      (v2_z_int2),
        .v2_w      (v2_w_int2),
        .plane_a   (plane_normal_x_i),
        .plane_b   (plane_normal_y_i),
        .plane_c   (plane_normal_z_i),
        .plane_d   (plane_offset_i),
        .intersect_x (intersect2_x),
        .intersect_y (intersect2_y),
        .intersect_z (intersect2_z),
        .intersect_w (intersect2_w),
        .done_o    (intersect_calc_done2)
    );

    logic dot_products_done;
    logic classification_done;

    always_ff @(posedge clk_i) begin
        if (curr_state == CLASSIFY && !dot_products_done) begin
            dot_product_v0 <= (
                ($signed(v0_x_i) * $signed(plane_normal_x_i)) +
                ($signed(v0_y_i) * $signed(plane_normal_y_i)) +
                ($signed(v0_z_i) * $signed(plane_normal_z_i)) +
                ($signed(v0_w_i) * $signed(plane_offset_i))
            ) >>> 12;
            dot_product_v1 <= (
                ($signed(v1_x_i) * $signed(plane_normal_x_i)) +
                ($signed(v1_y_i) * $signed(plane_normal_y_i)) +
                ($signed(v1_z_i) * $signed(plane_normal_z_i)) +
                ($signed(v1_w_i) * $signed(plane_offset_i))
            ) >>> 12;
            dot_product_v2 <= (
                ($signed(v2_x_i) * $signed(plane_normal_x_i)) +
                ($signed(v2_y_i) * $signed(plane_normal_y_i)) +
                ($signed(v2_z_i) * $signed(plane_normal_z_i)) +
                ($signed(v2_w_i) * $signed(plane_offset_i))
            ) >>> 12;
            dot_products_done <= 1;
        end
        else if (curr_state != CLASSIFY) begin
            dot_products_done <= 0;
        end
        if (curr_state == CLASSIFY && dot_products_done) begin
            vertex_inside[0] <= (dot_product_v0 >= 0);
            vertex_inside[1] <= (dot_product_v1 >= 0);
            vertex_inside[2] <= (dot_product_v2 >= 0);
            vertex_inside_count <= (dot_product_v0 >= 0)
                                 + (dot_product_v1 >= 0)
                                 + (dot_product_v2 >= 0);
            classification_done <= 1;
        end
        else if (curr_state != CLASSIFY) begin
            classification_done <= 0;
        end
    end

    always_ff @(posedge clk_i) begin
        if (curr_state == CLIP) begin
            case (vertex_inside_count)
                2'd0: begin
                    valid_o         <= 0;
                    num_triangles_o <= 0;
                end
                2'd1: begin
                    valid_o         <= 1;
                    num_triangles_o <= 1;
                    if (vertex_inside[0]) begin
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v0_x_i, v0_y_i, v0_z_i, v0_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end
                    else if (vertex_inside[1]) begin
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v1_x_i, v1_y_i, v1_z_i, v1_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end
                    else begin
                        {clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o} <= {v2_x_i, v2_y_i, v2_z_i, v2_w_i};
                        {clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o} <= {intersect1_x, intersect1_y, intersect1_z, intersect1_w};
                        {clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o} <= {intersect2_x, intersect2_y, intersect2_z, intersect2_w};
                    end
                end
                2'd2: begin
                    valid_o         <= 1;
                    num_triangles_o <= 2;
                    if (!vertex_inside[0]) begin
                        {
                            clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
                            clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
                            clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o
                        } <= {
                            v1_x_i, v1_y_i, v1_z_i, v1_w_i,
                            v2_x_i, v2_y_i, v2_z_i, v2_w_i,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                        {
                            clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
                            clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
                            clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o
                        } <= {
                            v2_x_i, v2_y_i, v2_z_i, v2_w_i,
                            intersect2_x, intersect2_y, intersect2_z, intersect2_w,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                    end
                    else if (!vertex_inside[1]) begin
                        {
                            clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
                            clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
                            clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o
                        } <= {
                            v2_x_i, v2_y_i, v2_z_i, v2_w_i,
                            v0_x_i, v0_y_i, v0_z_i, v0_w_i,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                        {
                            clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
                            clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
                            clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o
                        } <= {
                            v0_x_i, v0_y_i, v0_z_i, v0_w_i,
                            intersect2_x, intersect2_y, intersect2_z, intersect2_w,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                    end
                    else begin
                        {
                            clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
                            clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
                            clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o
                        } <= {
                            v0_x_i, v0_y_i, v0_z_i, v0_w_i,
                            v1_x_i, v1_y_i, v1_z_i, v1_w_i,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                        {
                            clipped_v3_x_o, clipped_v3_y_o, clipped_v3_z_o, clipped_v3_w_o,
                            clipped_v4_x_o, clipped_v4_y_o, clipped_v4_z_o, clipped_v4_w_o,
                            clipped_v5_x_o, clipped_v5_y_o, clipped_v5_z_o, clipped_v5_w_o
                        } <= {
                            v1_x_i, v1_y_i, v1_z_i, v1_w_i,
                            intersect2_x, intersect2_y, intersect2_z, intersect2_w,
                            intersect1_x, intersect1_y, intersect1_z, intersect1_w
                        };
                    end
                end
                2'd3: begin
                    valid_o         <= 1;
                    num_triangles_o <= 1;
                    {
                        clipped_v0_x_o, clipped_v0_y_o, clipped_v0_z_o, clipped_v0_w_o,
                        clipped_v1_x_o, clipped_v1_y_o, clipped_v1_z_o, clipped_v1_w_o,
                        clipped_v2_x_o, clipped_v2_y_o, clipped_v2_z_o, clipped_v2_w_o
                    } <= {
                        v0_x_i, v0_y_i, v0_z_i, v0_w_i,
                        v1_x_i, v1_y_i, v1_z_i, v1_w_i,
                        v2_x_i, v2_y_i, v2_z_i, v2_w_i
                    };
                end
            endcase
        end
    end

endmodule
