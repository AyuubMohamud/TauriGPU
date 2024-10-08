module rrwd #(parameter NoR = 2, parameter NoS = 4, parameter FW = 64, parameter DW = 24) (
    input   wire logic                  core_clock_i,
    input   wire logic                  core_reset_i,

    input   wire logic [DW*(NoR)-1:0]   data_i,
    input   wire logic [NoR-1:0]        enqueue_pixel_i,
    output  wire logic [NoR-1:0]        full_o,

    input   wire logic [NoS-1:0]        thrend_state_i, // thrend means there is no explicit thread running
    output  wire logic [NoS-1:0]        reset_o, // start thread go to idle, start icache at new pc etc
    output  wire logic [DW-1:0]         data_o,
    output  wire logic [NoS-1:0]        write_coords_o
);
    // Number of shaders is actually number of shader **THREADS** very important distinction
    wire [NoR-1:0] read_fifo;
    wire logic [DW*(NoR)-1:0]   data;
    wire [NoR-1:0] empty_fifo;

    for (genvar i = 0; i < NoR; i++) begin : _instatiate_fifos_for_raster_outs
        sfifo #(FW, DW) sfifo_inst (core_clock_i, core_reset_i, enqueue_pixel_i[i], data_i[DW*(i+1)-1:DW*i], full_o[i], read_fifo[i],
        data[DW*(i+1)-1:DW*i], empty_fifo[i]);
    end
    
    // Look for next free shader
    reg [NoS-1:0] current_shader_bitvec = '1;
    logic found_free;
    logic [NoS-1:0] shader_bitvec;
    always_comb begin
        shader_bitvec = 0;
        found_free = 0;
        for (integer x = 0; x < NoS; x++) begin
            if (thrend_state_i[x]&!found_free&!current_shader_bitvec[x]) begin
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

    wire [DW-1:0] data_array [0:NoR-1];

    for (genvar i = 0; i < NoR; i++) begin : transform
        assign data_array[i] = data[DW*(i+1)-1:DW*i];
    end
    logic [NoR-1:0] selected_fifo;
    logic breakout;
    logic [DW-1:0] selected_data;
    always_comb begin
        selected_fifo = 0;
        breakout = 0;
        selected_data = 'x;
        for (integer x = 0; x < NoR; x++) begin
            if (!empty_fifo[x]&!breakout) begin
                breakout = 1;
                selected_fifo[x] = 1;
                selected_data = data_array[x];
            end
        end
    end
    assign read_fifo = {NoR{found_free}}&selected_fifo;
    assign data_o = selected_data;
    assign write_coords_o = current_shader_bitvec&{thrend_state_i}&{NoS{breakout}};
    assign reset_o = current_shader_bitvec&{thrend_state_i}&{NoS{breakout}};
endmodule
