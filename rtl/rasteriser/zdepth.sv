module rasteriser #(
    parameter WIDTH = 32,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input wire clk_i,

    output reg idk_o
);

    /*
        The z-depth test buffer should provide
            1. Pixel coordinates
            2. Barycentric coordinates

        which allows the SEU shader to interpolate texture coordinates from barycentric coordinates
    */

endmodule
