module sfifo2 #(
    parameter FW = 64, 
    parameter DW = 8
) ( // Just a circular buffer 
    input   wire logic i_clk,
    input   wire logic i_reset,

    // Write channel
    input   wire logic i_wr_en,
    input   wire logic [DW-1:0] i_wr_data,
    output  wire logic o_full,

    // Read side
    input   wire logic i_rd,
    output  logic [DW-1:0] o_rd_data,
    output  wire logic o_empty
);

    reg [DW-1:0] fifo [0:FW-1];
    reg [$clog2(FW):0] read_ptr = 0;
    reg [$clog2(FW):0] write_ptr = 0;

    initial begin
        for (integer i = 0; i < FW; i = i + 1) begin
            fifo[i] = 0;
        end
    end
    assign o_empty = (read_ptr == write_ptr);
    assign o_full = (write_ptr[$clog2(FW)] != read_ptr[$clog2(FW)]) & (read_ptr[$clog2(FW)-1:0] == write_ptr[$clog2(FW)-1:0]);
    assign o_rd_data = fifo[read_ptr[$clog2(FW)-1:0]];
    // Logic to handle the pointers
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            read_ptr <= 0;
            write_ptr <= 0;
        end
        if (~i_reset & i_wr_en & ~o_full) begin
            write_ptr <= write_ptr + 1;
        end
        if (~i_reset & i_rd & ~o_empty) begin
            read_ptr <= read_ptr + 1;
        end
    end
    // Logic to handle memories
    always_ff @(posedge i_clk) begin
        if (~i_reset & i_wr_en & ~o_full) begin
            fifo[write_ptr[$clog2(FW)-1:0]] <= i_wr_data;
        end
    end


`ifdef FORMAL
    reg p_valid;
    initial p_valid = 0;
    initial assume(!i_wr_en);
    initial assume(!i_rd);
    initial assume(!i_resetn);
    initial assume(write_ptr == 0);
    initial assume(read_ptr == 0);

    always @* begin
        assert(o_empty == (write_ptr-read_ptr == 0));
        assert(o_full == ((write_ptr[$clog2(FW)] != read_ptr[$clog2(FW)]) & (read_ptr[$clog2(FW)-1:0] == write_ptr[$clog2(FW)-1:0])) );
    end

    always @(posedge i_clk) begin
        p_valid <= 1;
    end

    always @(posedge i_clk) begin
        if ($past(i_wr_en) & $past(i_resetn) & $past(o_full) & p_valid) begin
            assert(overflow);
        end
        if ($past(i_rd) & $past(o_empty) & $past(i_resetn) & p_valid) begin
            assert(underflow);
        end
    end

    always @(posedge i_clk) begin
        if ($past(i_resetn) & $past(~o_full) & $past(i_wr_en) & p_valid) begin
            assert(write_ptr == ($past(write_ptr) + 1'b1));
        end
        if ($past(i_resetn) & $past(~o_empty) & $past(i_rd) & p_valid) begin
            assert(read_ptr == ($past(read_ptr) + 1'b1));
        end
        if ($past(i_resetn) & $past(o_full) & p_valid) begin
            assert($stable(write_ptr));
        end
        if ($past(i_resetn) & $past(o_empty) & p_valid) begin
            assert($stable(read_ptr));
        end
    end

    always @(posedge i_clk) begin
        if ($past(i_resetn) & ~($past(o_full)) & $past(i_wr_en) & p_valid) begin
            assert(fifo[$past(write_ptr[$clog2(FW)-1:0])] == $past(i_wr_data));
        end
        if ($past(i_resetn) & $past(~o_empty) & $past(i_rd) & p_valid) begin
            assert(o_rd_data == fifo[$past(read_ptr[$clog2(FW)-1:0])]);
        end
    end

`endif

endmodule : sfifo2
