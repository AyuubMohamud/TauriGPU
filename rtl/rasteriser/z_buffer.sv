module z_buffer #(
    parameter Z_SIZE = 8,
    parameter X_RES = 4,
    parameter Y_RES = 4,
    parameter X_PIXEL_SIZE = $clog2(X_RES),
    parameter Y_PIXEL_SIZE = $clog2(Y_RES),
    parameter ADDR_SIZE = 32
)(
    input logic clk_i,
    input logic rst_i,
    input logic start_i,
    input logic flush_i,
    input logic [X_PIXEL_SIZE-1:0] pixel_x_i,
    input logic [Y_PIXEL_SIZE-1:0] pixel_y_i,
    input logic [Z_SIZE-1:0] pixel_z_i,
    input logic [2:0] z_depth_func_i,
    input logic [ADDR_SIZE-1:0] buffer_base_address_i,
    
    output logic buf_r_w,
    output logic [Z_SIZE-1:0] buf_data_w,
    input logic [Z_SIZE-1:0] buf_data_r,
    output logic [ADDR_SIZE-1:0] buf_addr,
    
    input logic data_r_valid,
    output logic data_r_ready,
    output logic data_w_valid,
    input logic data_w_ready,
    
    output logic flush_done_o,
    output logic depth_pass_o,
    output logic done_o
);

    // Internal signals
    logic need_update;
    logic update_complete;
    logic [$clog2(Y_RES*X_RES)-1:0] offset;
    logic [ADDR_SIZE-1:0] addr;
    logic depth_comparison_result;
    
    // Calculate pixel offset
    assign offset = pixel_y_i * X_RES + pixel_x_i;
    assign addr = buffer_base_address_i + offset;

    // Depth comparison function types
    typedef enum logic [2:0] {
        GL_NEVER = 3'b000,
        GL_LESS = 3'b001,
        GL_LEQUAL = 3'b010,
        GL_GREATER = 3'b011,
        GL_GEQUAL = 3'b100,
        GL_EQUAL = 3'b101,
        GL_NOTEQUAL = 3'b110,
        GL_ALWAYS = 3'b111
    } z_func_t;

    // State definitions
    typedef enum logic [2:0] {
        IDLE,
        READ,
        WRITE,
        RENDER_DONE,
        FLUSH,
        DONE
    } state_t;

    state_t curr_state, next_state;

    // Next state logic
    always_comb begin
        next_state = curr_state;
        case (curr_state)
            IDLE: next_state = start_i ? (flush_i ? FLUSH : READ) : IDLE;
            READ: begin
                if (data_r_valid && data_r_ready) begin
                    next_state = depth_comparison_result ? WRITE : RENDER_DONE;
                end else begin
                    next_state = READ;  // Stay in READ until we get valid data
                end
            end
            WRITE: begin
                if (data_w_valid && data_w_ready) begin
                    next_state = RENDER_DONE;
                end else begin
                    next_state = WRITE;  // Stay in WRITE until write completes
                end
            end
            RENDER_DONE: next_state = DONE;
            FLUSH: next_state = flush_done_o ? DONE : FLUSH;
            DONE: next_state = IDLE;
        endcase
    end

    // Depth comparison logic
    always_comb begin
        case (z_depth_func_i)
            GL_NEVER: depth_comparison_result = 1'b0;
            GL_LESS: depth_comparison_result = (pixel_z_i < buf_data_r);
            GL_LEQUAL: depth_comparison_result = (pixel_z_i <= buf_data_r);
            GL_GREATER: depth_comparison_result = (pixel_z_i > buf_data_r);
            GL_GEQUAL: depth_comparison_result = (pixel_z_i >= buf_data_r);
            GL_EQUAL: depth_comparison_result = (pixel_z_i == buf_data_r);
            GL_NOTEQUAL: depth_comparison_result = (pixel_z_i != buf_data_r);
            GL_ALWAYS: depth_comparison_result = 1'b1;
            default: depth_comparison_result = (pixel_z_i < buf_data_r);
        endcase
    end

    // Sequential logic
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            curr_state <= IDLE;
            buf_r_w <= 1'b1;
            buf_data_w <= '0;
            buf_addr <= '0;
            data_r_ready <= 1'b0;
            data_w_valid <= 1'b0;
            depth_pass_o <= 1'b0;
            done_o <= 1'b0;
            flush_done_o <= 1'b0;
            need_update <= 1'b0;
            update_complete <= 1'b0;
        end else begin
            curr_state <= next_state;
            
            case (curr_state)
                IDLE: begin
                    flush_done_o <= 1'b0;
                    update_complete <= 1'b0;
                    done_o <= 1'b0;
                    buf_r_w <= 1'b1;
                    data_r_ready <= 1'b0;
                    data_w_valid <= 1'b0;
                end

                READ: begin
                    buf_r_w <= 1'b1;
                    buf_addr <= addr;
                    data_w_valid <= 1'b0;
                    
                    // Only assert ready when we're actually in READ state
                    data_r_ready <= (next_state == READ);
                    
                    // Handle the read response
                    if (data_r_valid && data_r_ready) begin
                        depth_pass_o <= depth_comparison_result;
                        need_update <= depth_comparison_result;
                    end
                end

                WRITE: begin
                    if (!data_w_valid) begin
                        // Initialize write operation
                        buf_r_w <= 1'b0;
                        buf_data_w <= pixel_z_i;
                        buf_addr <= addr;
                        data_w_valid <= 1'b1;
                    end
                    else if (data_w_ready) begin
                        // Write completed
                        need_update <= 1'b0;
                        data_w_valid <= 1'b0;
                    end
                end

                RENDER_DONE: begin
                    update_complete <= 1'b1;
                    data_w_valid <= 1'b0;
                    data_r_ready <= 1'b0;
                end

                FLUSH: begin
                    // Initialize on first cycle
                    if (curr_state != FLUSH) begin
                        buf_r_w <= 1'b0;
                        buf_data_w <= {Z_SIZE{1'b1}}; // Maximum depth value (255 for 8-bit)
                        buf_addr <= buffer_base_address_i;
                        data_w_valid <= 1'b1;
                        flush_done_o <= 1'b0;
                    end
                    // Handle writes
                    else if (data_w_valid && data_w_ready) begin
                        // Write current address
                        if (buf_addr < (buffer_base_address_i + X_RES * Y_RES - 1)) begin
                            // Increment to next address
                            buf_addr <= buf_addr + 1;
                            data_w_valid <= 1'b1;
                        end else begin
                            // Last address written
                            flush_done_o <= 1'b1;
                            data_w_valid <= 1'b0;
                            buf_addr <= '0;  // Reset address counter
                        end
                    end
                    // Wait for write ready
                    else if (!data_w_ready) begin
                        data_w_valid <= 1'b1;  // Keep trying to write
                    end
                end

                DONE: begin
                    done_o <= 1'b1;
                    data_w_valid <= 1'b0;
                    data_r_ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
