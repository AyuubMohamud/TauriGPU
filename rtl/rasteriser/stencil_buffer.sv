module stencil_buffer #(
    parameter PIXEL_SIZE = 32,
    parameter BUFFER_SIZE = 8,
    parameter X_RES = 1280,
    parameter Y_RES = 720
)(
    input logic clk_i,

    // GPU control signals
    input logic [7:0] ref_val_i, // stencil reference value
    input logic start_i, // start stencil test
    input logic [2:0] func_i, // stencil test function
    input logic [?] mask_i, // !stencil mask
    input logic [PIXEL_SIZE-1:0] stencil_i, // Stencil value from fragment shader

    output logic stencil_pass_o,
    output logic done_o
);
    
    /* 
        The stencil buffer typically shares the same memory space as the z-buffer
        
        Alpha test -> stencil test -> depth test

        The stencil buffer is used to mask out fragments that should not be rendered
        The fragment's stencil value (unsigned integer) is tested against the stencil buffer's value - if the test fails, the fragment is culled
    */

    // Stencil buffer
    logic [PIXEL_SIZE-1:0] stencil_buffer [X_RES-1:0][Y_RES-1:0] = '{default: '0};

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

    always_ff @(posedge clk) begin
        if (start_i) begin
            done_o <= 0;
        end
    end

    always_comb begin
        case (func_i)
            GL_NEVER: stencil_pass_o = 0;
            GL_LESS: stencil_pass_o = (stencil_i < ref_val_i);
            GL_LEQUAL: stencil_pass_o = (stencil_i <= ref_val_i);
            GL_GREATER: stencil_pass_o = (stencil_i > ref_val_i);
            GL_GEQUAL: stencil_pass_o = (stencil_i >= ref_val_i);
            GL_EQUAL: stencil_pass_o = (stencil_i == ref_val_i);
            GL_NOTEQUAL: stencil_pass_o = (stencil_i != ref_val_i);
            GL_ALWAYS: stencil_pass_o = 1;
            default: stencil_pass_o = 0;
        endcase
    end

endmodule
