module intersection #(
    parameter VERTEX_WIDTH = 32,
    parameter FRAC_BITS = 16,  // Number of fractional bits for fixed-point representation
    parameter NEWTON_ITERATIONS = 3  // Number of Newton-Raphson iterations
)(
    input wire clk_i,
    input wire start_i,
    
    // Vertex 1 (inside vertex)
    input logic signed [VERTEX_WIDTH-1:0] v1_x, v1_y, v1_z, v1_w,
    // Vertex 2 (outside vertex)
    input logic signed [VERTEX_WIDTH-1:0] v2_x, v2_y, v2_z, v2_w,
    // Plane equation coefficients
    input logic signed [VERTEX_WIDTH-1:0] plane_a, plane_b, plane_c, plane_d,
    
    // Intersection point
    output logic signed [VERTEX_WIDTH-1:0] intersect_x, intersect_y, intersect_z, intersect_w,
    output logic done_o
);

    // Internal signals
    logic signed [VERTEX_WIDTH-1:0] t_num, t_den;
    logic signed [VERTEX_WIDTH-1:0] t;
    logic signed [VERTEX_WIDTH-1:0] reciprocal;
    logic signed [2*VERTEX_WIDTH-1:0] mul_temp;

    // State machine
    typedef enum logic [2:0] {
        IDLE,
        CALCULATE_T_NUM,
        CALCULATE_T_DEN,
        RECIPROCAL_INIT,
        RECIPROCAL_ITERATE,
        CALCULATE_T,
        INTERPOLATE,
        DONE
    } state_t;

    state_t state, next_state;
    logic [$clog2(NEWTON_ITERATIONS):0] iteration_count;

    always_ff @(posedge clk_i) begin
        if (start_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start_i) next_state = CALCULATE_T_NUM;
            CALCULATE_T_NUM: next_state = CALCULATE_T_DEN;
            CALCULATE_T_DEN: next_state = RECIPROCAL_INIT;
            RECIPROCAL_INIT: next_state = RECIPROCAL_ITERATE;
            RECIPROCAL_ITERATE: begin
                if (iteration_count == NEWTON_ITERATIONS - 1)
                    next_state = CALCULATE_T;
            end
            CALCULATE_T: next_state = INTERPOLATE;
            INTERPOLATE: next_state = DONE;
            DONE: next_state = IDLE;
        endcase
    end

    // Calculation logic
    always_ff @(posedge clk_i) begin
        case (state)
            CALCULATE_T_NUM: begin
                // Calculate t_num
                mul_temp = $signed(plane_a) * $signed(v1_x);
                t_num = -mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_b) * $signed(v1_y);
                t_num = t_num - mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_c) * $signed(v1_z);
                t_num = t_num - mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_d) * $signed(v1_w);
                t_num = t_num - mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
            end

            CALCULATE_T_DEN: begin
                // Calculate t_den
                mul_temp = $signed(plane_a) * $signed(v2_x - v1_x);
                t_den = mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_b) * $signed(v2_y - v1_y);
                t_den = t_den + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_c) * $signed(v2_z - v1_z);
                t_den = t_den + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                
                mul_temp = $signed(plane_d) * $signed(v2_w - v1_w);
                t_den = t_den + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
            end

            RECIPROCAL_INIT: begin
                reciprocal <= (1 << (VERTEX_WIDTH - 2)) / (t_den >>> (VERTEX_WIDTH - FRAC_BITS - 1));
                iteration_count <= 0;
            end

            RECIPROCAL_ITERATE: begin
                // Newton-Raphson iteration: x = x * (2 - d * x)
                mul_temp = $signed(t_den) * $signed(reciprocal);
                mul_temp = (2 << FRAC_BITS) - mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                mul_temp = $signed(reciprocal) * $signed(mul_temp);
                reciprocal <= mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
                iteration_count <= iteration_count + 1;
            end

            CALCULATE_T: begin
                mul_temp = $signed(t_num) * $signed(reciprocal);
                t <= mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
            end

            INTERPOLATE: begin
                mul_temp = $signed(t) * $signed(v2_x - v1_x);
                intersect_x <= v1_x + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];

                mul_temp = $signed(t) * $signed(v2_y - v1_y);
                intersect_y <= v1_y + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];

                mul_temp = $signed(t) * $signed(v2_z - v1_z);
                intersect_z <= v1_z + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];

                mul_temp = $signed(t) * $signed(v2_w - v1_w);
                intersect_w <= v1_w + mul_temp[VERTEX_WIDTH-1+FRAC_BITS:FRAC_BITS];
            end

            DONE: done_o <= 1'b1;
            default: done_o <= 1'b0;
        endcase
    end

endmodule
