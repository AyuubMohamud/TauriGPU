module rasteriser #(
    parameter WIDTH = 32,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input wire clk_i,

    output reg idk_o
);

    /* Culling
        Removes triangles outside the camera FOV
    */

    /* 
        World -> Camera -> Image Coordinate System
    */

    /* 
        Edge function
    */



endmodule
