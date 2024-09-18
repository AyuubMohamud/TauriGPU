module z_buffer #(
    // parameter PIXEL_SIZE = 32,
    parameter Z_SIZE = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input logic clk_i,
    input logic start_i,

    // Z-buffer control signals
    input logic flush_i,                            // reset buffer every frame (CPU signal)
    input logic [$clog2(X_RES)-1:0] pixel_x_i,
    input logic [$clog2(Y_RES)-1:0] pixel_y_i, 
    input logic [Z_SIZE-1:0] pixel_z_i,
    input logic [2:0] z_depth_func_i,

    output logic depth_pass_o,                      // render
    output logic done_o
);

    /*
        Tests if the fragment should be rendered by comparing the fragment's z value to the z-buffer's value

        ** Implementation of the z-buffer can be modified based on whether you are normalizing the depth values to [0,1]
        
        ** https://fgiesen.wordpress.com/2011/07/08/a-trip-through-the-graphics-pipeline-2011-part-7/
        ** Early Z is not implemented here <--
        
    */

    // Single pixel buffer
    typedef struct packed {
        logic valid;
        logic [Z_SIZE-1:0] z;
    } pixel_buffer;
    
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

    typedef enum logic [2:0] {
        GL_NEVER = 3'b000,
        GL_LESS = 3'b001,
        GL_LEQUAL = 3'b010,
        GL_GREATER = 3'b011,
        GL_GEQUAL = 3'b100,
        GL_EQUAL = 3'b101,
        GL_NOTEQUAL = 3'b110,
        GL_ALWAYS = 3'b111
    } z_func_t;

    // State machine
    typedef enum logic [1:0] {
        IDLE,
        RENDER,
        FLUSH,
        DONE
    } state_t;

    state_t curr_state, next_state;
    
    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: next_state = RENDER;
            RENDER: next_state = FLUSH;
            FLUSH: next_state = DONE;
            DONE: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk_i) begin
        // State machine
        if (!start_i) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end

        // Compare and render state
        if (curr_state == RENDER) begin
            if (depth_pass_o) begin
                z_buffer_array[pixel_x_i][pixel_y_i].z <= pixel_z_i;
                z_buffer_array[pixel_x_i][pixel_y_i].valid <= 1;
            end
        end

        // Flush state
        if ((curr_state == FLUSH) && flush_i) begin
            // Flush entire buffer
            for (int x = 0; x < X_RES; x++) begin
                for (int y = 0; y < Y_RES; y++) begin
                    z_buffer_array[x][y].valid <= 0;
                    z_buffer_array[x][y].z <= 0;
                end
            end
        end

        // Done state
        if (curr_state == DONE) begin // ** might want another signal
            done_o <= 1;
        end else begin
            done_o <= 0;
        end
    end

    always_comb begin
        case (z_depth_func_i)
            GL_NEVER: depth_pass_o = 0;
            GL_LESS: depth_pass_o = (pixel_z_i < z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_LEQUAL: depth_pass_o = (pixel_z_i <= z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_GREATER: depth_pass_o = (pixel_z_i > z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_GEQUAL: depth_pass_o = (pixel_z_i >= z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_EQUAL: depth_pass_o = (pixel_z_i == z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_NOTEQUAL: depth_pass_o = (pixel_z_i != z_buffer_array[pixel_x_i][pixel_y_i].z);
            GL_ALWAYS: depth_pass_o = 1;

            /* OpenGL: By default, the depth function GL_LESS is used*/
            default: depth_pass_o = (pixel_z_i < z_buffer_array[pixel_x_i][pixel_y_i].z);
        endcase
    end

endmodule
