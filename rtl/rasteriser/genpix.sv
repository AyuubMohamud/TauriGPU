module genpix (
    input   wire logic                  clock_i,
    input   wire logic                  reset_i,

    input   wire logic [23:0]           area_i, // 20.4 (unsigned)
    input   wire logic [16:0]           dl_w0_col_i,
    input   wire logic [16:0]           dl_w1_col_i,
    input   wire logic [16:0]           dl_w2_col_i,
    input   wire logic [16:0]           dl_w0_row_i,
    input   wire logic [16:0]           dl_w1_row_i,
    input   wire logic [16:0]           dl_w2_row_i,
    input   wire logic [24:0]           w0_row_i, // s.20.4
    input   wire logic [24:0]           w1_row_i, // s.20.4
    input   wire logic [24:0]           w2_row_i, // s.20.4
    input   wire logic [11:0]           x_min_i,
    input   wire logic [11:0]           y_min_i,
    input   wire logic [11:0]           x_max_i,
    input   wire logic [11:0]           y_max_i,
    input   wire logic                  valid_i,
    output  wire logic                  busy_o,


    output       logic [11:0]           x_o,
    output       logic [11:0]           y_o,
    output       logic [24:0]           w0_o,
    output       logic [24:0]           w1_o,
    output       logic [24:0]           w2_o,
    output       logic [23:0]           area_o,
    output       logic                  valid_o,
    input   wire logic                  busy_i
);
    // aim for up to one pixel every cycle
    wire complete;
    typedef enum { IDLE, PIXEL_OUT, COMPLETE } rasterizer_state_t;
    rasterizer_state_t rasterizer_state = IDLE;
    assign busy_o = !complete;
    assign complete = rasterizer_state == COMPLETE && !busy_i;
    reg [24:0] w0_row;
    reg [24:0] w1_row;
    reg [24:0] w2_row;
    reg [24:0] w0;
    reg [24:0] w1;
    reg [24:0] w2;
    reg [11:0] x_c;
    reg [11:0] y_c;

    wire [11:0] xpp;
    wire [11:0] ypp;
    wire change_row = xpp>x_max_i;
    wire complete_rz = ypp>y_max_i;

    assign xpp = x_c+1;
    assign ypp = y_c+1;
    
    wire [24:0] w0_next_row;
    wire [24:0] w1_next_row;
    wire [24:0] w2_next_row;
    assign w0_next_row = w0_row+{{8{dl_w0_row_i[16]}}, dl_w0_row_i};
    assign w1_next_row = w1_row+{{8{dl_w1_row_i[16]}}, dl_w1_row_i};
    assign w2_next_row = w2_row+{{8{dl_w2_row_i[16]}}, dl_w2_row_i};

    wire is_inside = !w0[24]&!w1[24]&!w2[24];
    always_ff @(posedge clock_i) begin
        case (rasterizer_state)
            IDLE: begin
                if (valid_i) begin
                    rasterizer_state <= PIXEL_OUT;
                    w0 <= w0_row_i;
                    w1 <= w1_row_i;
                    w2 <= w2_row_i;
                    x_c <= x_min_i;
                    y_c <= y_min_i;
                    w0_row <= w0_row_i;
                    w1_row <= w1_row_i;
                    w2_row <= w2_row_i;
                end
            end
            PIXEL_OUT: begin
                if (!busy_i) begin
                    w0 <= change_row ? w0_next_row : w0+{{8{dl_w0_col_i[16]}}, dl_w0_col_i};
                    w1 <= change_row ? w1_next_row : w1+{{8{dl_w1_col_i[16]}}, dl_w1_col_i};
                    w2 <= change_row ? w2_next_row : w2+{{8{dl_w2_col_i[16]}}, dl_w2_col_i};
    
                    w0_row <= change_row ? w0_next_row : w0_row;
                    w1_row <= change_row ? w1_next_row : w1_row;
                    w2_row <= change_row ? w2_next_row : w2_row;
    
                    x_c <= change_row ? x_min_i : xpp;
                    y_c <= change_row ? ypp : y_c;
    
                    valid_o <= is_inside;
                    x_o <= x_c;
                    y_o <= y_c;
                    w0_o <= w0;
                    w1_o <= w1;
                    w2_o <= w2;
                    area_o <= area_i;
                    if (complete_rz&&change_row) begin
                        rasterizer_state <= COMPLETE;
                    end
                end
            end
            COMPLETE: begin
                if (!busy_i) begin
                    rasterizer_state <= IDLE;
                end
            end
        endcase
    end

endmodule
