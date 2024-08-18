module geoshader #(
    parameter VERTEX_WIDTH = 32,
    parameter FRUSTUM_WIDTH = 32,
    parameter NUM_PLANES = 6,
    parameter MAX_TRIANGLES = 64
)(
    input wire clk_i,
    input wire start_i,

    // Input triangle
    input logic [VERTEX_WIDTH-1:0] v0_x_i, v0_y_i, v0_z_i, v0_w_i,
    input logic [VERTEX_WIDTH-1:0] v1_x_i, v1_y_i, v1_z_i, v1_w_i,
    input logic [VERTEX_WIDTH-1:0] v2_x_i, v2_y_i, v2_z_i, v2_w_i,

    // Clipping planes
    input logic [FRUSTUM_WIDTH-1:0] plane_a_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_b_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_c_i[NUM_PLANES],
    input logic [FRUSTUM_WIDTH-1:0] plane_d_i[NUM_PLANES],

    // Output to rasterizer
    output logic [VERTEX_WIDTH-1:0] v0_x_o, v0_y_o, v0_z_o, v0_w_o,
    output logic [VERTEX_WIDTH-1:0] v1_x_o, v1_y_o, v1_z_o, v1_w_o,
    output logic [VERTEX_WIDTH-1:0] v2_x_o, v2_y_o, v2_z_o, v2_w_o,

    output logic done_o
);

    /*
        Consider adding a frustum cull and backface cull before clipping

        Geoshader (clipping) is a fully serial process:
            Triangle --> [[FIFO1 --> Clipper --> FIFO2]] --> Rasterizer
            FIFO1 reads from triangle input when start_i and plane counter is 0
            FIFO2 loops back to FIFO1 while plane counter is less than 6
            FIFO2 outputs to rasterizer when plane counter is 6
    */

    // Signals for FIFO control
    logic [2:0] plane_counter = 0;
    logic fifo1_wr, fifo1_full, fifo1_empty, fifo1_read;
    logic fifo2_wr, fifo2_full, fifo2_empty, fifo2_read;

    // FIFO1 Data
    logic [VERTEX_WIDTH-1:0] v0_x_fifo1, v0_y_fifo1, v0_z_fifo1, v0_w_fifo1;
    logic [VERTEX_WIDTH-1:0] v1_x_fifo1, v1_y_fifo1, v1_z_fifo1, v1_w_fifo1;
    logic [VERTEX_WIDTH-1:0] v2_x_fifo1, v2_y_fifo1, v2_z_fifo1, v2_w_fifo1;

    logic [VERTEX_WIDTH*12-1:0] fifo1_data_in, fifo1_data_out;

    // Clipper output intermediate values (two triangles out of clipper)
    logic [VERTEX_WIDTH-1:0] v0_x_fifo2_t1, v0_y_fifo2_t1, v0_z_fifo2_t1, v0_w_fifo2_t1;
    logic [VERTEX_WIDTH-1:0] v1_x_fifo2_t1, v1_y_fifo2_t1, v1_z_fifo2_t1, v1_w_fifo2_t1;
    logic [VERTEX_WIDTH-1:0] v2_x_fifo2_t1, v2_y_fifo2_t1, v2_z_fifo2_t1, v2_w_fifo2_t1;

    logic [VERTEX_WIDTH-1:0] v0_x_fifo2_t2, v0_y_fifo2_t2, v0_z_fifo2_t2, v0_w_fifo2_t2;
    logic [VERTEX_WIDTH-1:0] v1_x_fifo2_t2, v1_y_fifo2_t2, v1_z_fifo2_t2, v1_w_fifo2_t2;
    logic [VERTEX_WIDTH-1:0] v2_x_fifo2_t2, v2_y_fifo2_t2, v2_z_fifo2_t2, v2_w_fifo2_t2;

    // Clipper to FIFO2 data
    logic [VERTEX_WIDTH-1:0] v0_x_fifo2_in, v0_y_fifo2_in, v0_z_fifo2_in, v0_w_fifo2_in;
    logic [VERTEX_WIDTH-1:0] v1_x_fifo2_in, v1_y_fifo2_in, v1_z_fifo2_in, v1_w_fifo2_in;
    logic [VERTEX_WIDTH-1:0] v2_x_fifo2_in, v2_y_fifo2_in, v2_z_fifo2_in, v2_w_fifo2_in;

    logic [VERTEX_WIDTH*12-1:0] fifo2_data_in, fifo2_data_out;

    // Signals for clipper control
    logic clip_done, clip_start, clip_valid;
    logic [1:0] clip_num_triangles;

    // Signals for clipper
    // Makes sure that I am not reading planes from a new frustum
    logic [FRUSTUM_WIDTH-1:0] curr_plane_a, curr_plane_b, curr_plane_c, curr_plane_d;
    assign curr_plane_a = plane_a_i[plane_counter];
    assign curr_plane_b = plane_b_i[plane_counter];
    assign curr_plane_c = plane_c_i[plane_counter];
    assign curr_plane_d = plane_d_i[plane_counter];

    // State machine
    typedef enum logic [2:0] {
        IDLE,
        FIFO_R, // (FIFO2 or triangle input) --> FIFO1
        CLIP, // FIFO1 --> Clipper
        FIFO_W // Clipper --> FIFO2
    } state_t;
    
    state_t curr_state, next_state;

    always_ff @(posedge clk_i) begin
        curr_state <= next_state;
    end
    
    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE:
                begin
                    done_o <= 0;
                    if (!start_i) begin
                        next_state = IDLE;
                        plane_counter <= 0;
                    end else begin
                        next_state = FIFO_R;
                    end
                end
            FIFO_R:
                begin 
                    if (plane_counter != 0 && !fifo2_empty) begin
                        next_state = FIFO_R;
                    end else if (plane_counter != 0 && fifo2_empty) begin
                        plane_counter += 1; // Increment before clipping for correct plane in wires
                        next_state = CLIP; // All triangles from FIFO2 have been written to FIFO1, start clipping 
                    end else if (plane_counter == 0) begin
                        plane_counter = 1; // Initialises plane counter to 1, since only first triangle is read from input (only happens once, which is in the first cycle)
                        next_state = CLIP; // Read original triangle from input and write to FIFO1, should be one cycle, then start clipping
                    end
                end
            CLIP:
                begin
                    if (!fifo1_empty) begin
                        next_state = CLIP; // While FIFO1 is not empty, read triangle from FIFO1 and clip against current plane
                    end else begin
                        next_state = FIFO_W;
                    end
                end
            FIFO_W:
                begin
                    if (done_o) begin
                        next_state = IDLE;
                    end else if (!done_o && plane_counter == 6) begin
                        next_state = FIFO_W; // Keep writing to rasterizer until FIFO2 is empty
                    end else begin
                        next_state = FIFO_R;
                    end
                end
        endcase
    end

    // FIFO_R stage
    always_ff @(posedge clk_i) begin
        if (curr_state == FIFO_R) begin
            if (plane_counter == 0) begin
                // Triangle input --> FIFO1
                v0_x_fifo1 <= v0_x_i;
                v0_y_fifo1 <= v0_y_i;
                v0_z_fifo1 <= v0_z_i;
                v0_w_fifo1 <= v0_w_i;
                v1_x_fifo1 <= v1_x_i;
                v1_y_fifo1 <= v1_y_i;
                v1_z_fifo1 <= v1_z_i;
                v1_w_fifo1 <= v1_w_i;
                v2_x_fifo1 <= v2_x_i;
                v2_y_fifo1 <= v2_y_i;
                v2_z_fifo1 <= v2_z_i;
                v2_w_fifo1 <= v2_w_i;
                
                fifo1_wr <= 1;
                fifo1_data_in <= {v0_x_fifo1, v0_y_fifo1, v0_z_fifo1, v0_w_fifo1, v1_x_fifo1, v1_y_fifo1, v1_z_fifo1, v1_w_fifo1, v2_x_fifo1, v2_y_fifo1, v2_z_fifo1, v2_w_fifo1};
                fifo1_wr <= 0;

            end else begin
                // Read from FIFO2 --> FIFO1
                if (!fifo2_empty) begin
                    fifo2_read <= 1;
                end
                
                // Extract vertex data from FIFO2 output and send FIFO2 data to FIFO1
                v0_x_fifo1 <= fifo2_data_out[VERTEX_WIDTH*12-1 : VERTEX_WIDTH*11];
                v0_y_fifo1 <= fifo2_data_out[VERTEX_WIDTH*11-1 : VERTEX_WIDTH*10];
                v0_z_fifo1 <= fifo2_data_out[VERTEX_WIDTH*10-1 : VERTEX_WIDTH*9];
                v0_w_fifo1 <= fifo2_data_out[VERTEX_WIDTH*9-1 : VERTEX_WIDTH*8];

                v1_x_fifo1 <= fifo2_data_out[VERTEX_WIDTH*8-1 : VERTEX_WIDTH*7];
                v1_y_fifo1 <= fifo2_data_out[VERTEX_WIDTH*7-1 : VERTEX_WIDTH*6];
                v1_z_fifo1 <= fifo2_data_out[VERTEX_WIDTH*6-1 : VERTEX_WIDTH*5];
                v1_w_fifo1 <= fifo2_data_out[VERTEX_WIDTH*5-1 : VERTEX_WIDTH*4];

                v2_x_fifo1 <= fifo2_data_out[VERTEX_WIDTH*4-1 : VERTEX_WIDTH*3];
                v2_y_fifo1 <= fifo2_data_out[VERTEX_WIDTH*3-1 : VERTEX_WIDTH*2];
                v2_z_fifo1 <= fifo2_data_out[VERTEX_WIDTH*2-1 : VERTEX_WIDTH*1];
                v2_w_fifo1 <= fifo2_data_out[VERTEX_WIDTH*1-1 : VERTEX_WIDTH*0];

                fifo2_read <= 0;

                fifo1_wr <= 1;
                fifo1_data_in <= {v0_x_fifo1, v0_y_fifo1, v0_z_fifo1, v0_w_fifo1, v1_x_fifo1, v1_y_fifo1, v1_z_fifo1, v1_w_fifo1, v2_x_fifo1, v2_y_fifo1, v2_z_fifo1, v2_w_fifo1};
                fifo1_wr <= 0;
            end
        end
    end
    
    // CLIP stage
    always_ff @(posedge clk_i) begin
        if (curr_state == CLIP) begin
            // While FIFO1 is not empty, read triangle from FIFO1 and clip against current plane
            if (!fifo1_empty) begin
                fifo1_read <= 1;
            end

            // ** v?_?_fifo1 is the input to the clipper

            v0_x_fifo1 <= fifo1_data_out[VERTEX_WIDTH*12-1 : VERTEX_WIDTH*11];
            v0_y_fifo1 <= fifo1_data_out[VERTEX_WIDTH*11-1 : VERTEX_WIDTH*10];
            v0_z_fifo1 <= fifo1_data_out[VERTEX_WIDTH*10-1 : VERTEX_WIDTH*9];
            v0_w_fifo1 <= fifo1_data_out[VERTEX_WIDTH*9-1 : VERTEX_WIDTH*8];

            v1_x_fifo1 <= fifo1_data_out[VERTEX_WIDTH*8-1 : VERTEX_WIDTH*7];
            v1_y_fifo1 <= fifo1_data_out[VERTEX_WIDTH*7-1 : VERTEX_WIDTH*6];
            v1_z_fifo1 <= fifo1_data_out[VERTEX_WIDTH*6-1 : VERTEX_WIDTH*5];
            v1_w_fifo1 <= fifo1_data_out[VERTEX_WIDTH*5-1 : VERTEX_WIDTH*4];

            v2_x_fifo1 <= fifo1_data_out[VERTEX_WIDTH*4-1 : VERTEX_WIDTH*3];
            v2_y_fifo1 <= fifo1_data_out[VERTEX_WIDTH*3-1 : VERTEX_WIDTH*2];
            v2_z_fifo1 <= fifo1_data_out[VERTEX_WIDTH*2-1 : VERTEX_WIDTH*1];
            v2_w_fifo1 <= fifo1_data_out[VERTEX_WIDTH*1-1 : VERTEX_WIDTH*0];

            fifo1_read <= 0;

            // ** Then, write clipped triangle (from clipper output) to FIFO2

            if ((clip_num_triangles == 2) && clip_done) begin
                
                // Insert first triangle into FIFO2
                v0_x_fifo2_in <= v0_x_fifo2_t1;
                v0_y_fifo2_in <= v0_y_fifo2_t1;
                v0_z_fifo2_in <= v0_z_fifo2_t1;
                v0_w_fifo2_in <= v0_w_fifo2_t1;
                v1_x_fifo2_in <= v1_x_fifo2_t1;
                v1_y_fifo2_in <= v1_y_fifo2_t1;
                v1_z_fifo2_in <= v1_z_fifo2_t1;
                v1_w_fifo2_in <= v1_w_fifo2_t1;
                v2_x_fifo2_in <= v2_x_fifo2_t1;
                v2_y_fifo2_in <= v2_y_fifo2_t1;
                v2_z_fifo2_in <= v2_z_fifo2_t1;
                v2_w_fifo2_in <= v2_w_fifo2_t1;

                fifo2_wr <= 1;

                fifo2_data_in <= {v0_x_fifo2_in, v0_y_fifo2_in, v0_z_fifo2_in, v0_w_fifo2_in, v1_x_fifo2_in, v1_y_fifo2_in, v1_z_fifo2_in, v1_w_fifo2_in, v2_x_fifo2_in, v2_y_fifo2_in, v2_z_fifo2_in, v2_w_fifo2_in};

                fifo2_wr <= 0; // TODO: Check if this wr-en usage is correct

                // Insert second triangle into FIFO2
                v0_x_fifo2_in <= v0_x_fifo2_t2;
                v0_y_fifo2_in <= v0_y_fifo2_t2;
                v0_z_fifo2_in <= v0_z_fifo2_t2;
                v0_w_fifo2_in <= v0_w_fifo2_t2;
                v1_x_fifo2_in <= v1_x_fifo2_t2;
                v1_y_fifo2_in <= v1_y_fifo2_t2;
                v1_z_fifo2_in <= v1_z_fifo2_t2;
                v1_w_fifo2_in <= v1_w_fifo2_t2;
                v2_x_fifo2_in <= v2_x_fifo2_t2;
                v2_y_fifo2_in <= v2_y_fifo2_t2;
                v2_z_fifo2_in <= v2_z_fifo2_t2;
                v2_w_fifo2_in <= v2_w_fifo2_t2;

                fifo2_wr <= 1;

                fifo2_data_in <= {v0_x_fifo2_in, v0_y_fifo2_in, v0_z_fifo2_in, v0_w_fifo2_in, v1_x_fifo2_in, v1_y_fifo2_in, v1_z_fifo2_in, v1_w_fifo2_in, v2_x_fifo2_in, v2_y_fifo2_in, v2_z_fifo2_in, v2_w_fifo2_in};

                fifo2_wr <= 0;


            end else if ((clip_num_triangles == 1) && clip_done) begin
                v0_x_fifo2_in <= v0_x_fifo2_t1;
                v0_y_fifo2_in <= v0_y_fifo2_t1;
                v0_z_fifo2_in <= v0_z_fifo2_t1;
                v0_w_fifo2_in <= v0_w_fifo2_t1;
                v1_x_fifo2_in <= v1_x_fifo2_t1;
                v1_y_fifo2_in <= v1_y_fifo2_t1;
                v1_z_fifo2_in <= v1_z_fifo2_t1;
                v1_w_fifo2_in <= v1_w_fifo2_t1;
                v2_x_fifo2_in <= v2_x_fifo2_t1;
                v2_y_fifo2_in <= v2_y_fifo2_t1;
                v2_z_fifo2_in <= v2_z_fifo2_t1;
                v2_w_fifo2_in <= v2_w_fifo2_t1;
                
                fifo2_wr <= 1;

                fifo2_data_in <= {v0_x_fifo2_in, v0_y_fifo2_in, v0_z_fifo2_in, v0_w_fifo2_in, v1_x_fifo2_in, v1_y_fifo2_in, v1_z_fifo2_in, v1_w_fifo2_in, v2_x_fifo2_in, v2_y_fifo2_in, v2_z_fifo2_in, v2_w_fifo2_in};

                fifo2_wr <= 0;
            end
        end
    end
       
    // FIFO_W stage
    always_ff @(posedge clk_i) begin
        if (curr_state == FIFO_W) begin
            if (plane_counter == 6) begin
                // Write to rasterizer
                // While FIFO2 is not empty, write to rasterizer (make sure everything is read from FIFO2 to rasterizer)
                if (!fifo2_empty) begin
                    fifo2_read <= 1;
                end

                // Extract vertex data from FIFO2 output and send FIFO2 data to rasterizer
                v0_x_o <= fifo2_data_out[VERTEX_WIDTH*12-1 : VERTEX_WIDTH*11];
                v0_y_o <= fifo2_data_out[VERTEX_WIDTH*11-1 : VERTEX_WIDTH*10];
                v0_z_o <= fifo2_data_out[VERTEX_WIDTH*10-1 : VERTEX_WIDTH*9];
                v0_w_o <= fifo2_data_out[VERTEX_WIDTH*9-1 : VERTEX_WIDTH*8];

                v1_x_o <= fifo2_data_out[VERTEX_WIDTH*8-1 : VERTEX_WIDTH*7];
                v1_y_o <= fifo2_data_out[VERTEX_WIDTH*7-1 : VERTEX_WIDTH*6];
                v1_z_o <= fifo2_data_out[VERTEX_WIDTH*6-1 : VERTEX_WIDTH*5];
                v1_w_o <= fifo2_data_out[VERTEX_WIDTH*5-1 : VERTEX_WIDTH*4];

                v2_x_o <= fifo2_data_out[VERTEX_WIDTH*4-1 : VERTEX_WIDTH*3];
                v2_y_o <= fifo2_data_out[VERTEX_WIDTH*3-1 : VERTEX_WIDTH*2];
                v2_z_o <= fifo2_data_out[VERTEX_WIDTH*2-1 : VERTEX_WIDTH*1];
                v2_w_o <= fifo2_data_out[VERTEX_WIDTH*1-1 : VERTEX_WIDTH*0];

                fifo2_read <= 0;

                if (fifo2_empty) begin
                    done_o <= 1; // Resets state to IDLE, done with current triangle
                end
            end 
        end
    end

    sfifo2 #(
        .FW(64),
        .DW(VERTEX_WIDTH*12)
    ) fifo1 (
        .i_clk(clk_i),
        .i_reset(1'b0),
        .i_wr_en(fifo1_wr && ~fifo1_full),
        .i_wr_data(fifo1_data_in),
        .o_full(fifo1_full),
        .i_rd(fifo1_read),
        .o_rd_data(fifo1_data_out),
        .o_empty(fifo1_empty)
    );

    sfifo2 #(
        .FW(64),
        .DW(VERTEX_WIDTH*12)
    ) fifo2 (
        .i_clk(clk_i),
        .i_reset(1'b0),
        .i_wr_en(fifo2_wr && ~fifo2_full),
        .i_wr_data(fifo2_data_in),
        .o_full(fifo2_full),
        .i_rd(fifo2_read),
        .o_rd_data(fifo2_data_out),
        .o_empty(fifo2_empty)
    );

    clipper #(
        .VERTEX_WIDTH(32),
        .FRUSTUM_WIDTH(32)
    ) clipper_inst (
        .clk_i(clk_i),
        .start_i(start_i),

        .v0_x_i(v0_x_fifo1), .v0_y_i(v0_y_fifo1), .v0_z_i(v0_z_fifo1), .v0_w_i(v0_w_fifo1),
        .v1_x_i(v1_x_fifo1), .v1_y_i(v1_y_fifo1), .v1_z_i(v1_z_fifo1), .v1_w_i(v1_w_fifo1),
        .v2_x_i(v2_x_fifo1), .v2_y_i(v2_y_fifo1), .v2_z_i(v2_z_fifo1), .v2_w_i(v2_w_fifo1),

        .plane_a_i(curr_plane_a),
        .plane_b_i(curr_plane_b),
        .plane_c_i(curr_plane_c),
        .plane_d_i(curr_plane_d),

        .clipped_v0_x_o(v0_x_fifo2_t1), .clipped_v0_y_o(v0_y_fifo2_t1), .clipped_v0_z_o(v0_z_fifo2_t1), .clipped_v0_w_o(v0_w_fifo2_t1),
        .clipped_v1_x_o(v1_x_fifo2_t1), .clipped_v1_y_o(v1_y_fifo2_t1), .clipped_v1_z_o(v1_z_fifo2_t1), .clipped_v1_w_o(v1_w_fifo2_t1),
        .clipped_v2_x_o(v2_x_fifo2_t1), .clipped_v2_y_o(v2_y_fifo2_t1), .clipped_v2_z_o(v2_z_fifo2_t1), .clipped_v2_w_o(v2_w_fifo2_t1),

        .clipped_v3_x_o(v0_x_fifo2_t2), .clipped_v3_y_o(v0_y_fifo2_t2), .clipped_v3_z_o(v0_z_fifo2_t2), .clipped_v3_w_o(v0_w_fifo2_t2),
        .clipped_v4_x_o(v1_x_fifo2_t2), .clipped_v4_y_o(v1_y_fifo2_t2), .clipped_v4_z_o(v1_z_fifo2_t2), .clipped_v4_w_o(v1_w_fifo2_t2),
        .clipped_v5_x_o(v2_x_fifo2_t2), .clipped_v5_y_o(v2_y_fifo2_t2), .clipped_v5_z_o(v2_z_fifo2_t2), .clipped_v5_w_o(v2_w_fifo2_t2),

        .done_o(clip_done),
        .valid_o(clip_valid),
        .num_triangles_o(clip_num_triangles)
    );

endmodule
