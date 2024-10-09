module z_buffer #(
    parameter Z_SIZE = 8,
    /*
        8-bit depth buffer: 256 levels of depth, modify for higher precision
        0 to 255 (0 is closest to the camera, 255 is farthest)
            --> represents the normalized range from 0 to 1 (mapped from NDC range of -1 to 1)
    */
    // parameter X_RES = 1280,
    // parameter Y_RES = 720,
    parameter X_RES = 4,
    parameter Y_RES = 4,
    parameter X_PIXEL_SIZE = $clog2(X_RES),
    parameter Y_PIXEL_SIZE = $clog2(Y_RES)
)(
    input logic clk_i,
    input logic start_i,                            // glEnable(GL_DEPTH_TEST)

    // Z-buffer control signals
    input logic flush_i,                            // reset buffer every frame (glClear(GL_DEPTH_BUFFER_BIT))
    input logic [X_PIXEL_SIZE-1:0] pixel_x_i,
    input logic [Y_PIXEL_SIZE-1:0] pixel_y_i, 
    input logic [Z_SIZE-1:0] pixel_z_i,
    input logic [2:0] z_depth_func_i,

    output logic flush_done_o,
    output logic depth_pass_o,                      // render
    output logic done_o
);

    /*
        Tests if the fragment should be rendered by comparing the fragment's z value to the z-buffer's value

        ** Implementation of the z-buffer can be modified based on whether you are normalizing the depth values to [0,1]
        
        ** https://fgiesen.wordpress.com/2011/07/08/a-trip-through-the-graphics-pipeline-2011-part-7/
        ** Early Z is not implemented here <--
        
        Note: The value written into the depth buffer is always the fragment's z value if the test passes, regardless of the depth function
    */

    // Signals
    logic need_update;
    logic update_complete;
    
    // Single pixel buffer
    typedef struct packed {
        // logic valid;
        logic [Z_SIZE-1:0] z;
    } pixel_buffer;

    pixel_buffer z_buffer_array[X_RES-1:0][Y_RES-1:0];
    
    // Extra signals for debugging
    logic [Z_SIZE-1:0] curr_buffer_z;
    assign curr_buffer_z = z_buffer_array[pixel_x_i][pixel_y_i].z;

    // Init buffer
    initial begin
        for (int x = 0; x < X_RES; x++) begin
            for (int y = 0; y < Y_RES; y++) begin
                z_buffer_array[x][y].z = 8'd255; // Farthest point
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
            IDLE: next_state = start_i ? RENDER : IDLE;
            RENDER: next_state = update_complete ? (flush_i ? FLUSH : DONE) : RENDER;
            FLUSH: next_state = flush_done_o ? DONE : FLUSH;
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

        if (curr_state == IDLE) begin
            flush_done_o <= 0;
            update_complete <= 0;
        end

        // Compare and render state
        if (curr_state == RENDER) begin
            need_update <= depth_pass_o ? 1 : 0;
            if (need_update) begin
                z_buffer_array[pixel_x_i][pixel_y_i].z <= pixel_z_i;
                need_update <= 0;
                update_complete <= 1;
            end else begin
                update_complete <= 1;
            end
        end

        // Flush state
        if (curr_state == FLUSH) begin
            if (flush_i) begin
                // Flush entire buffer
                for (int x = 0; x < X_RES; x++) begin
                    for (int y = 0; y < Y_RES; y++) begin
                        z_buffer_array[x][y].z <= 8'd255;
                    end
                end
                flush_done_o <= 1;
            end
        end

        // Done state
        if (curr_state == DONE) begin
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
