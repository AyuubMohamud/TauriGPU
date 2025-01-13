`include "regs_def.svh"
module taurigpu_regs #(
    parameter TL_RS = 4,
    localparam [7:0] VERSION = 8'd1,
    localparam [7:0] FEATURE = 8'd0
) (
    input   wire logic                  tilelink_clock_i,
    input   wire logic                  tilelink_reset_i,
    
    input   wire logic [2:0]            tauri_regs_a_opcode,
    input   wire logic [2:0]            tauri_regs_a_param,
    input   wire logic [3:0]            tauri_regs_a_size,
    input   wire logic [TL_RS-1:0]      tauri_regs_a_source,
    input   wire logic [11:0]           tauri_regs_a_address,
    input   wire logic [3:0]            tauri_regs_a_mask,
    input   wire logic [31:0]           tauri_regs_a_data,
    input   wire logic                  tauri_regs_a_corrupt,
    input   wire logic                  tauri_regs_a_valid,
    output  wire logic                  tauri_regs_a_ready,

    output  wire logic [2:0]            tauri_regs_d_opcode,
    output  wire logic [1:0]            tauri_regs_d_param,
    output  wire logic [3:0]            tauri_regs_d_size,
    output  wire logic [TL_RS-1:0]      tauri_regs_d_source,
    output  wire logic                  tauri_regs_d_denied,
    output  wire logic [31:0]           tauri_regs_d_data,
    output  wire logic                  tauri_regs_d_corrupt,
    output  wire logic                  tauri_regs_d_valid,
    input   wire logic                  tauri_regs_d_ready,

    output  tauri_tip_ctrl              tip_ctrl_o,
    output  tauri_tip_addr              tip_addr_o,
    output  tauri_tsu_addr              tsu_addr_o,
    output  tauri_zt_ctrl               zt_ctrl_o,
    output  tauri_zt_addr               zt_addr_o,
    output  tauri_st_ctrl               st_ctrl_o,
    output  tauri_st_addr               st_addr_o,
    output  tauri_fbops_ctrl            fbops_ctrl_o,
    output  tauri_fbops_addr            fbops_addr_o,
    output  wire logic                  submit_o,
    output  wire logic                  gpu_irq_o
);

    wire logic [2:0]            a_opcode;
    /* verilator lint_off UNUSED */
    wire logic [2:0]            a_param;
    /* verilator lint_on UNUSED */
    wire logic [3:0]            a_size;
    wire logic [TL_RS-1:0]      a_source;
    wire logic [11:0]           a_address;
    /* verilator lint_off UNUSED */
    wire logic [3:0]            a_mask;
    /* verilator lint_on UNUSED */
    wire logic [31:0]           a_data;
    /* verilator lint_off UNUSED */
    wire logic                  a_corrupt;
    /* verilator lint_on UNUSED */
    wire logic                  a_valid;

    skdbf #(.DW(63), .SYNC(0)) regs_skidbuffer (
        .clk_i(tilelink_clock_i),
        .rst_i(tilelink_reset_i),
        .combinational_ready_i(tauri_regs_d_ready),
        .cycle_data_o({
            a_opcode,
            a_param,
            a_size,
            a_source,
            a_address,
            a_mask,
            a_data,
            a_corrupt
        }),
        .cycle_vld_o(a_valid),
        .registered_ready_o(tauri_regs_a_ready),
        .registered_data_i({
            tauri_regs_a_opcode,
            tauri_regs_a_param,
            tauri_regs_a_size,
            tauri_regs_a_source,
            tauri_regs_a_address,
            tauri_regs_a_mask,
            tauri_regs_a_data,
            tauri_regs_a_corrupt
        }),
        .registered_vld_i(tauri_regs_a_valid)
    );

    /** Triangle Input Processor Registers **/
    tauri_tip_ctrl tip_ctrl; // Coordinate configurations
    tauri_tip_addr tip_addr; // Coordinate base address
    /** Triangle Setup Registers **/

    /** Pixel Generator Registers **/

    /** Tauri Shading Unit Registers **/
    tauri_tsu_addr tsu_addr; // Shader base address
    /** Z Buffer Control **/
    tauri_zt_ctrl  zt_ctrl; // Z Buffer control
    tauri_zt_addr  zt_addr; // Z Buffer base address
    /** Stencil Buffer control **/
    tauri_st_ctrl  st_ctrl; // Stencil Buffer control
    tauri_st_addr  st_addr; // Stencil Buffer base address
    /** Framebuffer Operations Control **/
    tauri_fbops_ctrl fbops_ctrl; // Framebuffer operations control
    tauri_fbops_addr fbops_addr; // Framebuffer base address

    logic [2:0]            d_opcode_q;
    logic [1:0]            d_param_q;
    logic [3:0]            d_size_q;
    logic [TL_RS-1:0]      d_source_q;
    logic                  d_denied_q;
    logic [31:0]           d_data_q;
    logic                  d_corrupt_q;
    logic                  d_valid_q;
    initial begin
        d_opcode_q = 3'd0;
        d_param_q = 2'd0;
        d_size_q = 4'd0;
        d_source_q = '0;
        d_denied_q = 1'b0;
        d_data_q = 32'd0;
        d_corrupt_q = 1'b0;
        d_valid_q = 1'b0;
        tip_ctrl.coord_type = INT16;
        tip_ctrl.coord_len = '0;
        tip_addr.tri_base_address = '0;
        tsu_addr.shader_base_addr = '0;
        zt_ctrl.z_en = '0;
        zt_ctrl.z_op = GL_NEVER;
        zt_addr.z_base_address = '0;
        st_ctrl.s_en = '0;
        st_ctrl.s_op = GL_KEEP;
        st_addr.s_base_address = '0;
        fbops_ctrl.fb_width = '0;
        fbops_ctrl.fb_height = '0;
        fbops_ctrl.fb_color = RGBA4444;
        fbops_addr.fb_base_address = '0;
    end

    always_ff @(posedge tilelink_clock_i) begin
        if (tilelink_reset_i) begin
            tip_ctrl.coord_type <= INT16;
            tip_ctrl.coord_len <= '0;
            tip_addr.tri_base_address <= '0;
            tsu_addr.shader_base_addr <= '0;
            zt_ctrl.z_en <= '0;
            zt_ctrl.z_op <= GL_NEVER;
            zt_addr.z_base_address <= '0;
            st_ctrl.s_en <= '0;
            st_ctrl.s_op <= GL_KEEP;
            st_addr.s_base_address <= '0;
            fbops_ctrl.fb_width <= '0;
            fbops_ctrl.fb_height <= '0;
            fbops_ctrl.fb_color <= RGBA4444;
            fbops_addr.fb_base_address <= '0;
        end else if (a_valid&tauri_regs_d_ready&(a_opcode==3'd0 || a_opcode==3'd1)) begin
            case (a_address)
                12'h000: begin
                    tip_ctrl.coord_type <= a_data[0];
                    tip_ctrl.coord_len <= a_data[31:1];
                end
                12'h004: begin
                    tip_addr.tri_base_address <= a_data;
                end
                12'h100: begin
                    tsu_addr.shader_base_addr <= a_data;
                end
                12'h200: begin
                    zt_ctrl.z_en <= a_data[0];
                    zt_ctrl.z_op <= a_data[3:1];
                end
                12'h204: begin
                    zt_addr.z_base_address <= a_data;
                end
                12'h300: begin
                    st_ctrl.s_en <= a_data[0];
                    st_ctrl.s_op <= a_data[3:1];
                end
                12'h304: begin
                    st_addr.s_base_address <= a_data;
                end
                12'h400: begin
                    fbops_ctrl.fb_width <= a_data[11:0];
                    fbops_ctrl.fb_height <= a_data[23:12];
                    fbops_ctrl.fb_color <= a_data[25:24];
                end
                12'h404: begin
                    fbops_addr.fb_base_address <= a_data;
                end
                default: begin
                    
                end
            endcase
        end
    end

    always_ff @(posedge tilelink_clock_i) begin
        if (tilelink_reset_i) begin
            d_valid_q <= 1'b0;
            d_corrupt_q <= 1'b0;
        end else if ((tauri_regs_d_ready|!d_valid_q)&a_valid) begin
            d_opcode_q <= a_opcode == 3'd4 ? 3'd1:3'd0;
            d_corrupt_q <= 1'b0;
            d_size_q <= a_size;
            d_denied_q <= 1'b0;
            d_param_q <= 2'd0;
            d_source_q <= a_source;
            case (a_address)
                12'h000: begin
                    d_data_q <= tip_ctrl;
                end
                12'h004: begin
                    d_data_q <= tip_addr;
                end
                12'h100: begin
                    d_data_q <= tsu_addr;
                end
                12'h200: begin
                    d_data_q <= {28'h0, zt_ctrl};
                end
                12'h204: begin
                    d_data_q <= zt_addr;
                end
                12'h300: begin
                    d_data_q <= {28'h0, st_ctrl};
                end
                12'h304: begin
                    d_data_q <= st_addr;
                end
                12'h400: begin
                    d_data_q <= {6'd0, fbops_ctrl};
                end
                12'h404: begin
                    d_data_q <= fbops_addr;
                end
                12'hFF4: begin
                    d_data_q <= {16'h7A51, VERSION, FEATURE};
                end
                default: begin

                end
            endcase
            d_valid_q <= 1'b1;
        end else if (tauri_regs_d_ready&!a_valid) begin
            d_valid_q <= 1'b0;
        end
    end
    assign tip_ctrl_o           =   tip_ctrl;
    assign tip_addr_o           =   tip_addr;
    assign tsu_addr_o           =   tsu_addr;
    assign zt_ctrl_o            =   zt_ctrl;
    assign zt_addr_o            =   zt_addr;
    assign st_ctrl_o            =   st_ctrl;
    assign st_addr_o            =   st_addr;
    assign fbops_ctrl_o         =   fbops_ctrl;
    assign fbops_addr_o         =   fbops_addr;
    assign gpu_irq_o            =   1'b0;
    assign tauri_regs_d_opcode  =   d_opcode_q;
    assign tauri_regs_d_param   =   d_param_q;
    assign tauri_regs_d_size    =   d_size_q;
    assign tauri_regs_d_source  =   d_source_q;
    assign tauri_regs_d_denied  =   d_denied_q;
    assign tauri_regs_d_data    =   d_data_q;
    assign tauri_regs_d_corrupt =   d_corrupt_q;
    assign tauri_regs_d_valid   =   d_valid_q;
    assign submit_o = a_valid&(tauri_regs_d_ready|!tauri_regs_d_valid)&(a_address==12'hFFC)&(a_opcode==3'd0 || a_opcode==3'd1);
endmodule
