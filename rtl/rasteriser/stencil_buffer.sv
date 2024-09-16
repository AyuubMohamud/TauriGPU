module stencil_buffer #(
    parameter PIXEL_SIZE = 32,
    parameter STENCIL_SIZE = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input logic clk_i,

    // Stencil func control signals
    input logic start_i,                                            // start stencil test (acts as "valid")
    input logic [STENCIL_SIZE-1:0] ref_val_i,                       // stencil reference value
    input logic [2:0] stencil_func_i,                               // stencil test function
    input logic [PIXEL_SIZE-1:0] mask_i[X_RES-1:0][Y_RES-1:0],      // stencil mask

    input logic [STENCIL_SIZE-1:0] frag_stencil_i,                  // stencil value from fragment shader

    // Stencil op control signals
    input logic [2:0] stencil_op_i,                                 // stencil operation
    input logic depth_pass_i,                                       // depth test result (from z_buffer's depth_pass_o)

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
        STENCIL_TEST,
        DONE
    } state_t;

    state_t curr_state, next_state;

    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: next_state = STENCIL_TEST;
            STENCIL_TEST: next_state = DONE;
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
            GL_LESS: stencil_pass_o = (frag_stencil_i < ref_val_i);
            GL_LEQUAL: stencil_pass_o = (frag_stencil_i <= ref_val_i);
            GL_GREATER: stencil_pass_o = (frag_stencil_i > ref_val_i);
            GL_GEQUAL: stencil_pass_o = (frag_stencil_i >= ref_val_i);
            GL_EQUAL: stencil_pass_o = (frag_stencil_i == ref_val_i);
            GL_NOTEQUAL: stencil_pass_o = (frag_stencil_i != ref_val_i);
            GL_ALWAYS: stencil_pass_o = 1;

            /* OpenGL: By default, the stencil function GL_ALWAYS is used*/
            default: stencil_pass_o = 1;
        endcase
    end

endmodule
