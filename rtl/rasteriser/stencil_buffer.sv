module stencil_buffer #(
    parameter WIDTH = 32;
)(
    input logic clk_i,

    // GPU control signals
    input logic [7:0] ref_val_i, // stencil reference value
    input logic start_i, // start stencil test

    // Fragment shader output
    

    // mask input
    // test function input
    // stencil buffer value

    input logic [WIDTH-1:0] stencil_i, // Stencil value from fragment shader

    output logic stencil_pass_o

);
    
    /* 
        The stencil buffer typically shares the same memory space as the z-buffer
        
        Alpha test -> stencil test -> depth test

        The stencil buffer is used to mask out fragments that should not be rendered
        The fragment's stencil value (unsigned integer) is tested against the stencil buffer's value - if the test fails, the fragment is culled
    */


endmodule
