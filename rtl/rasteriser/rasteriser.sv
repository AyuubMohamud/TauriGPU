// module rasteriser #(
//     parameter WIDTH = 32,
//     parameter VERTEX_WIDTH = 32,
//     parameter COLOR_DEPTH = 8,
//     parameter X_RES = 1280,
//     parameter Y_RES = 720
// )(
//     input wire clk_i,
//     input wire reset_i,
//     input wire start_i,
//     input logic [VERTEX_WIDTH-1:0] v0_x_i, v0_y_i, v1_x_i, v1_y_i, v2_x_i, v2_y_i,
//     input logic [COLOR_DEPTH*3-1:0] color0_i, color1_i, color2_i,

//     output logic [WIDTH-1:0] pixel_x_o,
//     output logic [WIDTH-1:0] pixel_y_o,
//     output logic [COLOR_DEPTH*3-1:0] pixel_color_o,
//     output logic pixel_valid_o,
//     output logic done_o
// );

//     typedef struct {
//         logic [WIDTH-1:0] x;
//         logic [WIDTH-1:0] y;
//     } vec2_t;

//     typedef struct {
//         logic [COLOR_DEPTH-1:0] b;
//         logic [COLOR_DEPTH-1:0] g;
//         logic [COLOR_DEPTH-1:0] r;
//     } color_t;

//     // State machine init
//     typedef enum {IDLE, INIT, CULL, COMPUTE, OUTPUT} state_t;
//     state_t state, next_state;

//     // Internal signals
//     vec2_t v0, v1, v2;
//     color_t color0, color1, color2;
//     logic [WIDTH-1:0] x_min, y_min, x_max, y_max;
//     logic [WIDTH-1:0] area;
//     logic [WIDTH-1:0] delta_w0_col, delta_w1_col, delta_w2_col;
//     logic [WIDTH-1:0] delta_w0_row, delta_w1_row, delta_w2_row;
//     logic [WIDTH-1:0] w0_row, w1_row, w2_row;
//     logic [WIDTH-1:0] w0, w1, w2;
//     logic [WIDTH-1:0] current_x, current_y;
//     logic [WIDTH-1:0] bias0, bias1, bias2;
//     logic is_inside; 

//     /* 
//         World -> Camera -> Image Coordinate System
//     */

//     // Top-left rule for edge-sharing (boolean)
//     function automatic logic is_top_left (input vec2_t edge_start, edge_end);
//         vec2_t edge;
//         logic is_top_edge, is_left_edge;

//         begin
//             edge.x = edge_end.x - edge_start.x;
//             edge.y = edge_end.y - edge_start.y;
//             is_top_edge = (edge.y == 0 && edge.x > 0);
//             is_left_edge = edge.y < 0;
//             return is_top_edge || is_left_edge;
//         end

//     endfunction

//     // Edge equation (cross product)
//     function automatic logic [WIDTH-1:0] edge_cross (input vec2_t a, b, p);
//         return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
//     endfunction

//     // State machine logic
//     always_ff @(posedge clk_i or posedge reset_i) begin
//         if (reset_i) begin
//             state <= IDLE;
//         end else begin
//             state <= next_state;
//         end
//     end

//     // State machine next state logic
//     always_comb begin
//         next_state = state;
//         case(state)
//             IDLE: if (start_i) next_state = INIT;
//             INIT: next_state = CULL;
//             CULL: begin
//                 if (x_max < 0 || x_min >= X_RES || y_max < 0 || y_min >= Y_RES) begin
//                     next_state = IDLE;
//                 end else begin
//                     next_state = COMPUTE;
//                 end
//             end
//             COMPUTE: begin
//                 if (current_y > y_max) begin // Outer loop for candidate pixels
//                     next_state = IDLE; 
//                 end else if (current_x > x_max) begin // Inner loop for candidate pixels
//                     next_state = COMPUTE; // Move to next row
//                 end else if (is_inside) begin
//                     next_state = OUTPUT;
//                     // If not inside, stay in COMPUTE to move to next pixel
//                 end
//             end
//             OUTPUT: next_state = COMPUTE;
//         endcase
//     end

//     // Main triangle fill logic
//     always_ff @(posedge clk_i or posedge reset_i) begin
//         if (reset_i) begin
//             // Reset all registers
//             v0 <= '0; v1 <= '0; v2 <= '0;
//             color0 <= '0; color1 <= '0; color2 <= '0;
//             x_min <= '0; y_min <= '0; x_max <= '0; y_max <= '0;
//             area <= '0;
//             delta_w0_col <= '0; delta_w1_col <= '0; delta_w2_col <= '0;
//             delta_w0_row <= '0; delta_w1_row <= '0; delta_w2_row <= '0;
//             w0_row <= '0; w1_row <= '0; w2_row <= '0;
//             current_x <= '0; current_y <= '0;
//             pixel_x_o <= '0; pixel_y_o <= '0;
//             pixel_color_o <= '0;
//             pixel_valid_o <= '0;
//             done_o <= '0;
//         end else begin
//             case (state)
//                 IDLE: begin
//                     done_o <= 0;
//                     pixel_valid_o <= 0;
//                     if (start_i) begin
//                         v0 <= '{v0_x_i, v0_y_i};
//                         v1 <= '{v1_x_i, v1_y_i};
//                         v2 <= '{v2_x_i, v2_y_i};
//                         color0 <= color0_i;
//                         color1 <= color1_i;
//                         color2 <= color2_i;
//                     end
//                 end
//                 INIT: begin
//                     // Compute bounding box
//                     x_min <= min(v0.x, min(v1.x, v2.x));
//                     y_min <= min(v0.y, min(v1.y, v2.y));
//                     x_max <= max(v0.x, max(v1.x, v2.x));
//                     y_max <= max(v0.y, max(v1.y, v2.y));

//                     // Compute area
//                     area <= edge_cross(v0, v1, v2);

//                     // Compute delta_s per step
//                     delta_w0_col <= v1.y - v2.y;
//                     delta_w1_col <= v2.y - v0.y;
//                     delta_w2_col <= v0.y - v1.y;
//                     delta_w0_row <= v2.x - v1.x;
//                     delta_w1_row <= v0.x - v2.x;
//                     delta_w2_row <= v1.x - v0.x;

//                     current_x <= x_min;
//                     current_y <= y_min;

//                     // Compute bias
//                     bias0 <= edge_cross(v1, v2, {x_min+0.5, y_min+0.5}); // TODO: The 0.5 is to account for the pixel center, but I'm not sure how to implement

//                     // Compute w0, w1, w2 edge equations
//                     w0_row <= edge_cross(v1, v2, v0) + bias0;
//                     w1_row <= edge_cross(v2, v0, v1) + bias1;
//                     w2_row <= edge_cross(v0, v1, v2) + bias2;

//                 end

//                 COMPUTE: begin
//                     if (current_x <= x_max) begin
//                         w0 <= w0_row;
//                         w1 <= w1_row;
//                         w2 <= w2_row;
//                         is_inside <= (w0 >= 0 && w1 >= 0 && w2 >= 0);
//                         current_x <= current_x + 1;
//                     end else begin
//                         current_x <= x_min;
//                         current_y <= current_y + 1;
//                         w0_row <= w0_row + delta_w0_row;
//                         w1_row <= w1_row + delta_w1_row;
//                         w2_row <= w2_row + delta_w2_row;
//                     end
//                 end

//                 OUTPUT: begin
//                     pixel_x_o <= current_x;
//                     pixel_y_o <= current_y;

//                     // Interpolate color
//                     pixel_color_o <= color0; // TODO: Use barycentric coordinates to interpolate color (need div)
//                     pixel_valid_o <= 1;
//                     current_x <= current_x + 1;
//                     w0_row <= w0_row + delta_w0_row;
//                     w1_row <= w1_row + delta_w1_row;
//                     w2_row <= w2_row + delta_w2_row;
//                 end
//             endcase
//         end
//     end

//     // Done signal
//     always_ff @(posedge clk_i or posedge reset_i) begin
//         if (reset_i) begin
//             done_o <= 0;
//         end else  if (state == COMPUTE && current_y > y_max) begin
//             done_o <= 1;
//         end
//     end
    
// endmodule
