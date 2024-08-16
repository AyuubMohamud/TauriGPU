module geoshader #(
    parameter VERTEX_WIDTH = 32,
    parameter FRUSTUM_WIDTH = 32,
    parameter NUM_PLANES = 6,
    parameter MAX_TRIANGLES = 64
)(
    input wire clk_i,
    input wire start_i,

    // Input triangle
    input logic [VERTEX_WIDTH-1:0] v0_x_i, v0_y_i, v0_z_i, v0_w_i,
    input logic [VERTEX_WIDTH-1:0] v1_x_i, v1_y_i, v1_z_i, v1_w_i,
    input logic [VERTEX_WIDTH-1:0] v2_x_i, v2_y_i, v2_z_i, v2_w_i,

    // Clipping planes (assuming 6 planes: left, right, top, bottom, near, far)
    input logic [FRUSTUM_WIDTH-1:0] plane_a_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_b_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_c_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_d_i[NUM_PLANES],

    // Output to rasterizer (assuming a maximum of MAX_TRIANGLES output triangles)
    output logic [VERTEX_WIDTH-1:0] out_v_x[MAX_TRIANGLES][3],
    output logic [VERTEX_WIDTH-1:0] out_v_y[MAX_TRIANGLES][3],
    output logic [VERTEX_WIDTH-1:0] out_v_z[MAX_TRIANGLES][3],
    output logic [VERTEX_WIDTH-1:0] out_v_w[MAX_TRIANGLES][3],
    output logic done_o
);

    // Creates a queue

    // The queue is used to store the vertices of the triangle

    // For each plane, the triangle in the queue is sent to `clipper.sv` and is clipped against the plane, and the clipped triangles are added to the queue

    // Repeat until all planes are clipped against. This makes sure that the clipped triangles are also clipped against all planes

    // Once all planes are clipped against, all the clipped triangles are sent to the rasteriser


    /*
        Main things to consider:
        - The frustum could change for each triangle from the vertex shader
        - The clipped triangles need to be clipped against all planes, but it could get confused with other new triangles added to the queue

        Hence you need to wait until the current triangle bunch is clipped against all planes before adding new triangles to the queue

        You can instantiate multiple `clipper.sv` modules to clip against all planes in parallel (multithread using fork join)
    */

    clipper clipper1(
        .clk_i(clk_i),
        .start_i(start_i),
        .v0_x_i(v0_x_i),
        .v0_y_i(v0_y_i),
        .v0_z_i(v0_z_i),
        .v0_w_i(v0_w_i),
        .v1_x_i(v1_x_i),
        .v1_y_i(v1_y_i),
        .v1_z_i(v1_z_i),
        .v1_w_i(v1_w_i),
        .v2_x_i(v2_x_i),
        .v2_y_i(v2_y_i),
        .v2_z_i(v2_z_i),
        .v2_w_i(v2_w_i),
        .plane_a_i(plane_a_i),
        .plane_b_i(plane_b_i),
        .plane_c_i(plane_c_i),
        .plane_d_i(plane_d_i),
        .out_v_x(out_v_x),
        .out_v_y(out_v_y),
        .out_v_z(out_v_z),
        .out_v_w(out_v_w),
        .done_o(done_o)
    );


endmodule
