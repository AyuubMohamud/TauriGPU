module new_rasteriser (
    input   wire logic                  rasteriser_clock_i,
    input   wire logic                  rasteriser_reset_i,

    input   wire logic [15:0]           rasteriser_a_x_i,
    input   wire logic [15:0]           rasteriser_a_y_i,
    input   wire logic [15:0]           rasteriser_b_x_i,
    input   wire logic [15:0]           rasteriser_b_y_i,
    input   wire logic [15:0]           rasteriser_c_x_i,
    input   wire logic [15:0]           rasteriser_c_y_i,
    input   wire logic                  rasteriser_valid_i,
    output  wire logic                  rasteriser_busy_o,

    output       logic [11:0]           x_o,
    output       logic [11:0]           y_o,
    output       logic [24:0]           w0_o,
    output       logic [24:0]           w1_o,
    output       logic [24:0]           w2_o,
    output       logic [23:0]           area_o,
    output       logic                  valid_o,
    input   wire logic                  busy_i
);

    logic [23:0]           setup_area;
    logic [16:0]           setup_dl_w0_col;
    logic [16:0]           setup_dl_w1_col;
    logic [16:0]           setup_dl_w2_col;
    logic [16:0]           setup_dl_w0_row;
    logic [16:0]           setup_dl_w1_row;
    logic [16:0]           setup_dl_w2_row;
    logic [24:0]           setup_w0_row;
    logic [24:0]           setup_w1_row;
    logic [24:0]           setup_w2_row;
    logic [11:0]           setup_x_min;
    logic [11:0]           setup_y_min;
    logic [11:0]           setup_x_max;
    logic [11:0]           setup_y_max;
    logic                  setup_valid;
    logic                  setup_busy;
    setup setup_inst (rasteriser_clock_i,
    rasteriser_reset_i,
    rasteriser_a_x_i,
    rasteriser_a_y_i,
    rasteriser_b_x_i,
    rasteriser_b_y_i,
    rasteriser_c_x_i,
    rasteriser_c_y_i,
    rasteriser_valid_i,
    rasteriser_busy_o,
    setup_area,
    setup_dl_w0_col,
    setup_dl_w1_col,
    setup_dl_w2_col,
    setup_dl_w0_row,
    setup_dl_w1_row,
    setup_dl_w2_row,
    setup_w0_row,
    setup_w1_row,
    setup_w2_row,
    setup_x_min,
    setup_y_min,
    setup_x_max,
    setup_y_max,
    setup_valid,
    setup_busy);

    genpix genpix_inst (
        rasteriser_clock_i,
        rasteriser_reset_i,
        setup_area,
        setup_dl_w0_col,
        setup_dl_w1_col,
        setup_dl_w2_col,
        setup_dl_w0_row,
        setup_dl_w1_row,
        setup_dl_w2_row,
        setup_w0_row,
        setup_w1_row,
        setup_w2_row,
        setup_x_min,
        setup_y_min,
        setup_x_max,
        setup_y_max,
        setup_valid,
        setup_busy,
        x_o,
        y_o,
        w0_o,
        w1_o,
        w2_o,
        area_o,
        valid_o,
        busy_i
    );

endmodule
