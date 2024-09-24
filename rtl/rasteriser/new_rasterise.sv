module rasteriser #(
    parameter WIDTH = 12,
    parameter VERTEX_WIDTH = 12,
    parameter COLOR_DEPTH = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input wire clk_i,
    input wire reset_i,
    input wire start_i,
    input logic [VERTEX_WIDTH-1:0] v0_x_i, v0_y_i, v1_x_i, v1_y_i, v2_x_i, v2_y_i,
    input logic [COLOR_DEPTH*3-1:0] color0_i, color1_i, color2_i,
    output wire logic busy_o,

    output logic [WIDTH-1:0] pixel_x_o,
    output logic [WIDTH-1:0] pixel_y_o,
    output logic [COLOR_DEPTH*3-1:0] pixel_color_o,
    output logic pixel_valid_o,
    output logic done_o
);

    typedef struct {
        logic [WIDTH-1:0] x;
        logic [WIDTH-1:0] y;
    } vec2_t;

    typedef struct {
        logic [COLOR_DEPTH-1:0] b;
        logic [COLOR_DEPTH-1:0] g;
        logic [COLOR_DEPTH-1:0] r;
    } color_t;

    // State machine init
    typedef enum {IDLE, INIT, COMPUTE, OUTPUT} state_t;
    state_t state, next_state;

    // Internal signals
    vec2_t v0, v1, v2;
    color_t color0, color1, color2;
    logic [WIDTH-1:0] x_min, y_min, x_max, y_max;
    logic [26:0] area;
    logic [26:0] delta_w0_col, delta_w1_col, delta_w2_col;
    logic [26:0] delta_w0_row, delta_w1_row, delta_w2_row;
    logic [26:0] w0_row, w1_row, w2_row;
    logic [26:0] w0, w1, w2;
    logic [WIDTH-1:0] current_x, current_y;
    logic [WIDTH-1:0] bias0, bias1, bias2;
    logic is_inside; 

    /* 
        World -> Camera -> Image Coordinate System
    */

    // Top-left rule for edge-sharing (boolean)
    //function automatic logic is_top_left (input vec2_t edge_start, edge_end);
    //    vec2_t Edge;
    //    logic is_top_edge, is_left_edge;
//
    //    begin
    //        Edge.x = edge_end.x - edge_start.x;
    //        Edge.y = edge_end.y - edge_start.y;
    //        is_top_edge = (Edge.y == 0 && Edge.x > 0);
    //        is_left_edge = Edge.y < 0;
    //        return is_top_edge || is_left_edge;
    //    end
//
    //endfunction

    // Edge equation (cross product)
    
    function logic [26:0] edge_cross (input vec2_t a, b, p);
        edge_cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
    endfunction

    function logic [WIDTH-1:0] max (input [WIDTH-1:0] a, b, c);
        logic [WIDTH-1:0] stage_1;
        assign stage_1 = b>c ? b : c;
        max = a>stage_1 ? a : stage_1;
    endfunction

    function logic [WIDTH-1:0] min (input [WIDTH-1:0] a, b, c);
        logic [WIDTH-1:0] stage_1;
        assign stage_1 = b<c ? b : c;
        min = a<stage_1 ? a : stage_1;
    endfunction

    // State machine logic
    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // State machine next state logic
    always_comb begin
        next_state = state;
        case(state)
            IDLE: if (start_i) next_state = INIT;
            INIT: next_state = COMPUTE;
            COMPUTE: begin
                if (current_y > y_max) begin // Outer loop for candidate pixels
                    next_state = IDLE; 
                end else if (current_x > x_max) begin // Inner loop for candidate pixels
                    next_state = COMPUTE; // Move to next row
                end else if (is_inside) begin
                    next_state = OUTPUT;
                    // If not inside, stay in COMPUTE to move to next pixel
                end
            end
            OUTPUT: next_state = COMPUTE;
        endcase
    end
    wire [12:0] delta_w0_colw = v1.y - v2.y;
    wire [12:0] delta_w1_colw = v2.y - v0.y;
    wire [12:0] delta_w2_colw = v0.y - v1.y;
    wire [12:0] delta_w0_roww = v2.x - v1.x;
    wire [12:0] delta_w1_roww = v0.x - v2.x;
    wire [12:0] delta_w2_roww = v1.x - v0.x;
    // Main triangle fill logic
    wire [11:0] x_min_w, y_min_w, x_max_w, y_max_w;
    min3 min30 (v0.x, v1.x, v2.x, x_min_w);     min3 min31 (v0.y, v1.y, v2.y, y_min_w);
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            // Reset all registers
            v0 <= '0; v1 <= '0; v2 <= '0;
            color0 <= '0; color1 <= '0; color2 <= '0;
            x_min <= '0; y_min <= '0; x_max <= '0; y_max <= '0;
            area <= '0;
            delta_w0_col <= '0; delta_w1_col <= '0; delta_w2_col <= '0;
            delta_w0_row <= '0; delta_w1_row <= '0; delta_w2_row <= '0;
            w0_row <= '0; w1_row <= '0; w2_row <= '0;
            current_x <= '0; current_y <= '0;
            pixel_x_o <= '0; pixel_y_o <= '0;
            pixel_color_o <= '0;
            pixel_valid_o <= '0;
            done_o <= '0;
        end else begin
            case (state)
                IDLE: begin
                    done_o <= 0;
                    pixel_valid_o <= 0;
                    if (start_i) begin
                        v0 <= '{v0_x_i, v0_y_i};
                        v1 <= '{v1_x_i, v1_y_i};
                        v2 <= '{v2_x_i, v2_y_i};
                        color0 <= color0_i;
                        color1 <= color1_i;
                        color2 <= color2_i;
                    end
                end
                INIT: begin
                    // Compute bounding box
                    x_min <= x_min_w;
                    y_min <= y_min_w;
                    x_max <= x_max_w;
                    y_max <= y_max_w;
                    // Compute area
                    area <= edge_cross(v0, v1, v2);

                    // Compute delta_s per step
                    delta_w0_col <= {{15{delta_w0_colw[12]}}, delta_w0_colw[11:0]};
                    delta_w1_col <= {{15{delta_w1_colw[12]}}, delta_w1_colw[11:0]};
                    delta_w2_col <= {{15{delta_w2_colw[12]}}, delta_w2_colw[11:0]};
                    delta_w0_row <= {{15{delta_w0_roww[12]}}, delta_w0_roww[11:0]};
                    delta_w1_row <= {{15{delta_w1_roww[12]}}, delta_w1_roww[11:0]};
                    delta_w2_row <= {{15{delta_w2_roww[12]}}, delta_w2_roww[11:0]};

                    current_x <= x_min;
                    current_y <= y_min;

                    // Compute bias
                    //bias0 <= edge_cross(v1, v2, {x_min+0.5, y_min+0.5}); // TODO: The 0.5 is to account for the pixel center, but I'm not sure how to implement

                    // Compute w0, w1, w2 edge equations
                    w0_row <= edge_cross(v1, v2, v0);
                    w1_row <= edge_cross(v2, v0, v1);
                    w2_row <= edge_cross(v0, v1, v2);
                end

                COMPUTE: begin
                    if (current_x <= x_max) begin
                        w0 <= w0_row;
                        w1 <= w1_row;
                        w2 <= w2_row;
                        is_inside <= (!w0[26] && !w1[26] && !w2[26]);
                        current_x <= current_x + 1;
                    end else begin
                        current_x <= x_min;
                        current_y <= current_y + 1;
                        w0_row <= w0_row + delta_w0_row;
                        w1_row <= w1_row + delta_w1_row;
                        w2_row <= w2_row + delta_w2_row;
                    end
                end

                OUTPUT: begin
                    pixel_x_o <= current_x;
                    pixel_y_o <= current_y;

                    // Interpolate color
                    pixel_color_o <= color0; // TODO: Use barycentric coordinates to interpolate color (need div)
                    pixel_valid_o <= 1;
                    current_x <= current_x + 1;
                    w0_row <= w0_row + delta_w0_row;
                    w1_row <= w1_row + delta_w1_row;
                    w2_row <= w2_row + delta_w2_row;
                end
            endcase
        end
    end

    // Done signal
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            done_o <= 0;
        end else  if (state == COMPUTE && current_y > y_max) begin
            done_o <= 1;
        end
    end
    
endmodule
