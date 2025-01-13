// Copyright (C) Ayuub Mohamud, 2024
// Licensed under CERN-OHL-P version 2
module skdbf #(
    parameter DW = 8,
    parameter SYNC = 0
) (
    input   wire logic          clk_i,
    input   wire logic          rst_i,
    // IP Side
    input   wire logic          combinational_ready_i,
    output       logic [DW-1:0] cycle_data_o,
    output       logic          cycle_vld_o,
    // Bus side
    output       logic          registered_ready_o,
    input   wire logic [DW-1:0] registered_data_i,
    input   wire logic          registered_vld_i 
);

    reg [DW-1:0] held_data = '0;
    reg held_vld = '0;

    wire hold_data;
    assign hold_data = !combinational_ready_i & registered_ready_o & cycle_vld_o & registered_vld_i;
    assign registered_ready_o = !held_vld;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            held_vld <= '0;
            held_data <= '0;
        end else if (hold_data) begin
            held_data <= registered_data_i;
            held_vld <= 1'b1;
        end else if (combinational_ready_i) begin
            held_vld <= '0;
        end
    end 

    generate if (SYNC) begin : __skdbf_if_sync
        initial cycle_vld_o = '0;
        initial cycle_data_o = '0;
        always_ff @(posedge clk_i) begin
            cycle_data_o <= held_vld ? held_data : registered_data_i;
            cycle_vld_o <= rst_i ? 1'b0 : held_vld|registered_vld_i;
        end
    end else begin : __skdbf_if_async
        assign cycle_data_o = held_vld ? held_data : registered_data_i;
        assign cycle_vld_o = held_vld|registered_vld_i;
    end endgenerate
`ifdef FORMAL
    reg p_valid = '0;
    always_ff @(posedge clk_i) p_valid <= '1;

    initial assume(combinational_ready_i == '0);
    initial assume(registered_vld_i == '0);
    initial assume(held_vld == '0);
    
    generate if (SYNC) begin : __skdbf_if_sync
        always_ff @(posedge clk_i) begin
            if ($past(rst_i)&p_valid) begin
                assert(cycle_vld_o=='0);
            end
        end
    end endgenerate
    always_ff @(posedge clk_i) begin
        if ($past(rst_i)&p_valid) begin
            assert(held_vld=='0);
        end
    end
    generate if (SYNC) begin : __skdbf_if_sync_formal
        always_ff @(posedge clk_i) begin
            if (p_valid&!$past(rst_i)&cycle_vld_o) begin
                assert(cycle_data_o==$past(held_data) || cycle_data_o==$past(registered_data_i));
            end

            if (p_valid&!$past(rst_i)) begin
                assert(cycle_vld_o==$past(registered_vld_i|held_vld));
            end
        end
    end
    else begin : __skdbf_if_async_formal
        always_comb begin
            assert(cycle_vld_o==(held_vld|registered_vld_i));
            assert(cycle_data_o==registered_data_i || cycle_data_o==held_data);
        end
    end endgenerate
    
    always_ff @(posedge clk_i) begin
        if (!$past(rst_i)&!rst_i&$past(registered_vld_i)&$past(!combinational_ready_i)&$past(registered_ready_o)&$past(cycle_vld_o)&p_valid) begin
            assert(held_vld == 1'b1);
        end
    end
`endif
endmodule
