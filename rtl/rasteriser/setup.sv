/**
    Triangle setup: takes coordinates in s.11.4

**/



module setup (
    input   wire logic                  clock_i,
    input   wire logic                  reset_i,
    
    input   wire logic [15:0]           a_x_i,
    input   wire logic [15:0]           a_y_i,
    input   wire logic [15:0]           b_x_i,
    input   wire logic [15:0]           b_y_i,
    input   wire logic [15:0]           c_x_i,
    input   wire logic [15:0]           c_y_i,
    input   wire logic                  valid_i,
    output  wire logic                  busy_o,

    output       logic [23:0]           area_o, // 20.4 (unsigned)
    output       logic [16:0]           dl_w0_col_o,
    output       logic [16:0]           dl_w1_col_o,
    output       logic [16:0]           dl_w2_col_o,
    output       logic [16:0]           dl_w0_row_o,
    output       logic [16:0]           dl_w1_row_o,
    output       logic [16:0]           dl_w2_row_o,
    output       logic [24:0]           w0_row_o, // s.20.4
    output       logic [24:0]           w1_row_o, // s.20.4
    output       logic [24:0]           w2_row_o, // s.20.4
    output       logic [11:0]           x_min_o,
    output       logic [11:0]           y_min_o,
    output       logic [11:0]           x_max_o,
    output       logic [11:0]           y_max_o,
    output       logic                  valid_o,
    input   wire logic                  busy_i
);
    localparam LOWINC = 16'h0001;
    localparam HALF =   16'h0008;
    wire [11:0] x_min;
    wire [11:0] y_min;
    wire [11:0] x_max;
    wire [11:0] y_max;
    wire [15:0] bias0;
    wire [15:0] bias1;
    wire [15:0] bias2;
    wire [15:0] p0_x, p0_y;
    wire [24:0] w0_row;
    wire [24:0] w1_row;
    wire [24:0] w2_row;
    /* verilator lint_off unused */
    wire [33:0] area;
    wire [33:0] w0_row_l;
    wire [33:0] w1_row_l;
    wire [33:0] w2_row_l;
    /* verilator lint_on unused */
    function static [11:0] min3;
        input [11:0] a, b, c;
        logic a_less_b = $signed(a)<$signed(b);
        logic b_less_c = $signed(b)<$signed(c);
        assign min3 = a_less_b&!b_less_c ? a : b_less_c ? b : c;
    endfunction
    function static [11:0] max3;
        input [11:0] a, b, c;
        logic a_more_b = $signed(a)>$signed(b);
        logic b_more_c = $signed(b)>$signed(c);
        assign max3 = a_more_b&b_more_c ? a : b_more_c ? b : c;
    endfunction
    function static [15:0] get_bias;
        input [15:0] st_x, st_y, ed_x, ed_y;
        logic [16:0] e_x = ed_x - st_x;
        logic [16:0] e_y = ed_y - st_y;
        assign get_bias = (e_x==0)||(e_y==0) ? '0 : LOWINC;
    endfunction
    function static [33:0] edge_cross;
        input [15:0] a_x, a_y, b_x, b_y, c_x, c_y;
        assign edge_cross = ($signed(b_x - a_x)*$signed(c_y-a_y)) - 
        ($signed(b_y-a_y)*$signed(c_x-a_x));
    endfunction
    
    assign area = edge_cross(a_x_i, a_y_i,
     b_x_i, b_y_i, c_x_i, c_y_i);
    
    // s.11.4 + s.11.4 -> s.12.4
    // s.12.4 * s.12.4 -> s.24.8
    // s.24.8 + s.24.8 -> s.25.8

    // not expecting area to be negative so only routing from area[27:4]

    assign x_min = min3(a_x_i[15:4], b_x_i[15:4], c_x_i[15:4]);
    assign y_min = min3(a_y_i[15:4], b_y_i[15:4], c_y_i[15:4]);
    assign x_max = max3(a_x_i[15:4], b_x_i[15:4], c_x_i[15:4]);
    assign y_max = max3(a_y_i[15:4], b_y_i[15:4], c_y_i[15:4]);

    assign bias0 = get_bias(b_x_i, b_y_i, c_x_i, c_y_i);
    assign bias1 = get_bias(b_x_i, b_y_i, a_x_i, a_y_i);
    assign bias2 = get_bias(a_x_i, a_y_i, b_x_i, b_y_i);

    
    assign p0_x = {x_min, 4'h0}+HALF;
    assign p0_y = {y_min, 4'h0}+HALF;

    assign w0_row_l = edge_cross(b_x_i, b_y_i, c_x_i, c_y_i, p0_x, p0_y);
    assign w1_row_l = edge_cross(c_x_i, c_y_i, a_x_i, a_y_i, p0_x, p0_y);
    assign w2_row_l = edge_cross(a_x_i, a_y_i, b_x_i, b_y_i, p0_x, p0_y);

    assign w0_row = {w0_row_l[33], w0_row_l[27:4]};
    assign w1_row = {w1_row_l[33], w1_row_l[27:4]};
    assign w2_row = {w2_row_l[33], w2_row_l[27:4]};

    assign busy_o = busy_i;
    always_ff @(posedge clock_i) begin
        if (reset_i) begin
            valid_o <= '0;
        end else if ((!busy_i&valid_i)|(!valid_o&valid_i)) begin
            area_o <= area[27:4];
            dl_w0_col_o <= b_y_i - c_y_i;
            dl_w1_col_o <= c_y_i - a_y_i;
            dl_w2_col_o <= a_y_i - b_y_i;
            dl_w0_row_o <= c_x_i - b_x_i;
            dl_w1_row_o <= a_x_i - c_x_i;
            dl_w2_row_o <= b_x_i - a_x_i;
            x_max_o <= x_max;
            y_max_o <= y_max;
            x_min_o <= x_min;
            y_min_o <= y_min;
            w0_row_o <= w0_row+{9'h0,bias0};
            w1_row_o <= w1_row+{9'h0,bias1};
            w2_row_o <= w2_row+{9'h0,bias2};
        end else if (!busy_i) begin
            valid_o <= '0;
        end
    end


endmodule
