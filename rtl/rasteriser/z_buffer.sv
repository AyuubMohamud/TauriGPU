module z_buffer #(
    parameter PIXEL_SIZE = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input logic clk_i,
    input logic start_i,
    input logic flush_i, // reset buffer every frame
    input logic [$clog2(X_RES)-1:0] pixel_x_i,
    input logic [$clog2(Y_RES)-1:0] pixel_y_i, 
    input logic [PIXEL_SIZE-1:0] pixel_z_i,

    output logic render_o,
    output logic done_o
);

    /*
        Tests if the fragment should be rendered by comparing the fragment's z value to the z-buffer's value

        ! Implementation of the z-buffer can be modified based on whether you are normalizing the depth values to [0,1]
    */

    // Single pixel buffer
    typedef struct packed {
        logic valid;
        logic [PIXEL_SIZE-1:0] z;
    } pixel_buffer;

    // Z-buffer memory
    pixel_buffer z_buffer_array[X_RES-1:0][Y_RES-1:0];

    // Init buffer
    initial begin
        for (int x = 0; x < X_RES; x++) begin
            for (int y = 0; y < Y_RES; y++) begin
                z_buffer_array[x][y].valid = 0;
                z_buffer_array[x][y].z = 0;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if (start_i) begin
            
            if (!z_buffer_array[pixel_x_i][pixel_y_i].valid) begin
                // If value is not valid, write to buffer
                z_buffer_array[pixel_x_i][pixel_y_i].z <= pixel_z_i;
                z_buffer_array[pixel_x_i][pixel_y_i].valid <= 1;
                render_o <= 1;
            end
            else if (pixel_z_i < z_buffer_array[pixel_x_i][pixel_y_i].z) begin
                z_buffer_array[pixel_x_i][pixel_y_i].z <= pixel_z_i;
                render_o <= 1;
            end
            else begin
                render_o <= 0;
            end

        end else if (flush_i) begin
            z_buffer_array[pixel_x_i][pixel_y_i].valid <= 0;
        end
        else begin
            done_o <= 0;
        end
    end

endmodule
