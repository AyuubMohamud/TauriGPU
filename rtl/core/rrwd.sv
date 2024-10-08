module rrwd #(parameter NoR = 2, parameter NoS = 4, parameter FW = 64) (
    input   wire logic                  core_clock_i,
    input   wire logic                  core_reset_i,

    input   wire logic [12*(NoR)-1:0]   integer_x_i,
    input   wire logic [12*(NoR)-1:0]   integer_y_i,
    input   wire logic [NoR-1:0]        enqueue_pixel_i,
    output  wire logic [NoR-1:0]        full_o,

    input   wire logic [NoS-1:0]        thrend_state_i, // thrend means there is no explicit thread running
    output  wire logic [NoS-1:0]        reset_o, // start thread go to idle, start icache at new pc etc
    output  wire logic [11:0]           int_coord_x_o,
    output  wire logic [11:0]           int_coord_y_o,
    output  wire logic [NoS-1:0]        write_coords_o
);
    // Number of shaders is actually number of shader **THREADS** very important distinction
    wire [NoR-1:0] read_fifo;
    wire logic [12*(NoR)-1:0]   integer_x;
    wire logic [12*(NoR)-1:0]   integer_y;
    wire [NoR-1:0] empty_fifo;

    for (genvar i = 0; i < NoR; i++) begin : _instatiate_fifos_for_raster_outs
        sfifo #(FW, 24) sfifo_inst (core_clock_i, core_reset_i, enqueue_pixel_i[i], {integer_x_i[12*(i+1)-1:12*(i)],
        integer_y_i[12*(i+1)-1:12*(i)]}, full_o[i], read_fifo[i], {integer_x[12*(i+1)-1:12*(i)],
        integer_y[12*(i+1)-1:12*(i)]}, empty_fifo[i]);
    end
    
    // Look for next free shader
    reg [NoS-1:0] current_shader_bitvec = 0;
    logic found_free;
    logic [NoS-1:0] shader_bitvec;
    always_comb begin
        shader_bitvec = 0;
        found_free = 0;
        for (integer x = 0; x < NoS; x++) begin
            if (thrend_state_i[x]&!found_free) begin
                found_free = 1;
                shader_bitvec[x] = 1;
            end
        end
    end
    always_ff @(posedge core_clock_i) begin
        current_shader_bitvec <= shader_bitvec;
    end
    /**
        Look for not empty fifo for the current shader
        if found push coords, if not then dont push them.
        move to next free shader
    
    **/

    wire [11:0] integer_x_array [0:NoR-1];
    wire [11:0] integer_y_array [0:NoR-1];

    for (genvar i = 0; i < NoR; i++) begin : transform
        assign integer_x_array[i] = integer_x[12*(i+1)-1:12*i];
        assign integer_y_array[i] = integer_y[12*(i+1)-1:12*i];
    end

    logic [NoR-1:0] selected_fifo;
    logic breakout;
    logic [11:0] selected_x;
    logic [11:0] selected_y;
    always_comb begin
        selected_fifo = 0;
        breakout = 0;
        selected_x = 'x;
        selected_y = 'x;
        for (integer x = 0; x < NoR; x++) begin
            if (!empty_fifo[x]&!breakout) begin
                breakout = 1;
                selected_fifo[x] = 1;
                selected_x = integer_x_array[x];
                selected_y = integer_y_array[x];
            end
        end
    end
    assign read_fifo = {NoR{found_free}}&selected_fifo;
    assign int_coord_x_o = selected_x;
    assign int_coord_y_o = selected_y;
    assign write_coords_o = current_shader_bitvec&{thrend_state_i}&{NoS{breakout}};
    assign reset_o = current_shader_bitvec&{thrend_state_i}&{NoS{breakout}};
endmodule
