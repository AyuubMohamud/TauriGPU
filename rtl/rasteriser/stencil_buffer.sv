module stencil_buffer #(
    parameter PIXEL_SIZE = 32,
    parameter STENCIL_SIZE = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input logic clk_i,

    // Fragment values
    input logic [$clog2(X_RES)-1:0] pixel_x_i,
    input logic [$clog2(Y_RES)-1:0] pixel_y_i,
    input logic [STENCIL_SIZE-1:0] frag_stencil_i,                  // stencil value of fragment

    // Stencil func control signals
    input logic start_i,                                            // start stencil test (acts as "valid")
    input logic [2:0] stencil_func_i,                               // stencil test function
    input logic flush_i,

    // Stencil op control signals
    input logic [2:0] sfail_i,                                      // stencil op - sfail
    input logic [2:0] dpfail_i,                                     // stencil op - dpfail
    input logic [2:0] dppass_i,                                     // stencil op - dppass
    input logic depth_pass_i,                                       // depth test result (from z_buffer's depth_pass_o)

    // Stencil buffer mapping (init from CPU)
    input logic [STENCIL_SIZE-1:0] stencil_buffer_map_i[X_RES-1:0][Y_RES-1:0],

    output logic stencil_pass_o,                                    // stencil test result
    output logic done_o

);
    
    /* 
        The stencil buffer typically shares the same memory space as the z-buffer
        
        Alpha test -> stencil test -> depth test

        The stencil buffer is used to mask out fragments that should not be rendered
        The fragment's stencil value (unsigned integer) is tested against the stencil buffer's value - if the test fails, the fragment is culled
    */

    // Stencil buffer
    typedef struct packed {
        logic valid;
        logic [STENCIL_SIZE-1:0] stencil;
    } stencil_buffer;

    stencil_buffer stencil_buffer_array[X_RES-1:0][Y_RES-1:0];
    logic [2:0] stencil_action;

    // Init buffer
    initial begin
        for (int x = 0; x < X_RES; x++) begin
            for (int y = 0; y < Y_RES; y++) begin
                stencil_buffer_array[x][y] = 0;
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
    } stencil_func_t;

    // State machine
    typedef enum logic [1:0] {
        IDLE,
        STENCIL_OP,
        FLUSH,
        DONE
    } state_t;

    state_t curr_state, next_state;

    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: next_state = STENCIL_OP;
            STENCIL_OP: next_state = FLUSH;
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

        // Stencil test state
        if (curr_state == STENCIL_OP) begin
            if (!stencil_pass_o) begin
                // Stencil fail
                stencil_action <= sfail_i;
            end else if (stencil_pass_o && !depth_pass_i) begin
                // Stencil pass, depth fail
                stencil_action <= dpfail_i;
            end else if (stencil_pass_o && depth_pass_i) begin
                // Stencil pass, depth pass
                stencil_action <= dppass_i;
            end
        end

        // Flush state
        if ((curr_state == FLUSH) && flush_i) begin
            for (int x = 0; x < X_RES; x++) begin
                for (int y = 0; y < Y_RES; y++) begin
                    stencil_buffer_array[x][y].valid <= 0;
                    stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= 0;
                end
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
        case (stencil_func_i)
            GL_NEVER: stencil_pass_o = 0;
            GL_LESS: stencil_pass_o = (frag_stencil_i < stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_LEQUAL: stencil_pass_o = (frag_stencil_i <= stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_GREATER: stencil_pass_o = (frag_stencil_i > stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_GEQUAL: stencil_pass_o = (frag_stencil_i >= stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_EQUAL: stencil_pass_o = (frag_stencil_i == stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_NOTEQUAL: stencil_pass_o = (frag_stencil_i != stencil_buffer_array[pixel_x_i][pixel_y_i].stencil);
            GL_ALWAYS: stencil_pass_o = 1;

            /* OpenGL: By default, the stencil function GL_ALWAYS is used*/
            default: stencil_pass_o = 1;
        endcase
    end

    typedef enum logic [2:0] {
        GL_KEEP = 3'b000,
        GL_ZERO = 3'b001,
        GL_REPLACE = 3'b010,
        GL_INCR = 3'b011,
        GL_INCR_WRAP = 3'b100,
        GL_DECR = 3'b101,
        GL_DECR_WRAP = 3'b110,
        GL_INVERT = 3'b111
    } stencil_op_t;


    always_ff @(posedge clk_i) begin
        case (stencil_action)
            GL_KEEP: begin
                // Do nothing - The currently stored stencil value is kept.
            end
            GL_ZERO: begin
                stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= 0;
            end
            GL_REPLACE: begin
                stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= frag_stencil_i;
            end
            GL_INCR: begin
                stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil + 1);
            end
            GL_INCR_WRAP: begin
                if (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil == (2**STENCIL_SIZE-1)) begin
                    stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= 0;
                end else begin
                    stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil + 1);
                end
            end
            GL_DECR: begin
                stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil - 1);
            end
            GL_DECR_WRAP: begin
                if (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil == 0) begin
                    stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= (2**STENCIL_SIZE-1);
                end else begin
                    stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= (stencil_buffer_array[pixel_x_i][pixel_y_i].stencil - 1);
                end
            end
            GL_INVERT: begin
                stencil_buffer_array[pixel_x_i][pixel_y_i].stencil <= ~stencil_buffer_array[pixel_x_i][pixel_y_i].stencil;
            end
        endcase
    end

endmodule
