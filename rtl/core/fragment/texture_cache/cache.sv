module cache (
    input   wire logic                      core_clock_i,
    input   wire logic [1:0]                texture_wrapS_mode_i,
    input   wire logic [1:0]                texture_wrapT_mode_i,
    input   wire logic [22:0]               texture_min_s_clamp_i,
    input   wire logic [22:0]               texture_max_s_clamp_i,
    input   wire logic [22:0]               texture_min_t_clamp_i,
    input   wire logic [22:0]               texture_max_t_clamp_i,
    input   wire logic [10:0]               tx_width,
    input   wire logic [10:0]               tx_height,
    input   wire logic [31:0]               tx_base,
    output       logic [2:0]                tx_idx,
    
    input   wire logic                      cache_flush_i,
    output  wire logic                      cache_flush_resp,

    input   wire logic [23:0]               texture_s_i,
    input   wire logic [23:0]               texture_t_i,
    input   wire logic                      texture_lkp_i,

    output  wire logic [23:0]               texture_o,
    output  wire logic                      texture_valid_o,

    input   wire logic [31:0]               dc_addr_i,
    input   wire logic [31:0]               dc_data_i,
    input   wire logic [2:0]                dc_op_i,
    input   wire logic                      dc_valid_i,

    output       logic [31:0]               dc_data_o,
    output       logic                      dc_valid_o,

    // TileLink Bus Master Uncached Heavyweight
    output       logic [2:0]                tcache_a_opcode,
    output       logic [2:0]                tcache_a_param,
    output       logic [3:0]                tcache_a_size,
    output       logic [31:0]               tcache_a_address,
    output       logic [3:0]                tcache_a_mask,
    output       logic [31:0]               tcache_a_data,
    output       logic                      tcache_a_corrupt,
    output       logic                      tcache_a_valid,
    input   wire logic                      tcache_a_ready,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic [2:0]                tcache_d_opcode,
    input   wire logic [1:0]                tcache_d_param,
    input   wire logic [3:0]                tcache_d_size,
    input   wire logic                      tcache_d_denied,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic [31:0]               tcache_d_data,
    /* verilator lint_off UNUSEDSIGNAL */
    input   wire logic                      tcache_d_corrupt,
    /* verilator lint_on UNUSEDSIGNAL */
    input   wire logic                      tcache_d_valid,
    output  wire logic                      tcache_d_ready
);
    wire busy;
    wire logic [14:0]               s;
    wire logic [14:0]               t;
    wire [10:0] x_0; wire [10:0] y_0;
    wire [21:0] offset;
    reg [14:0] s_1 = 0; reg [14:0] t_1 = 0;
    reg [10:0] i_1 = 0; reg [10:0] j_1 = 0;
    reg [21:0] texture_idx = 0;
    texCoordOps coordinates (texture_wrapS_mode_i,
    texture_wrapT_mode_i,
    texture_min_s_clamp_i,
    texture_max_s_clamp_i,
    texture_min_t_clamp_i,
    texture_max_t_clamp_i,
    texture_s_i, texture_t_i, s, t);
    texToInteger toInt (s_1,
    t_1,
    tx_width,
    tx_height,
    x_0,
    y_0);
    texAgen agen (i_1, j_1, tx_height, offset);
    reg [4:0] ffs;
    reg [31:0] full_address;
    always_ff @(posedge core_clock_i) begin
        s_1 <= busy ? s : s_1; t_1 <= busy ? t : t_1;
        i_1 <= busy ? x_0 : i_1; j_1 <= busy ? y_0 : j_1;
        texture_idx <= busy ? offset : texture_idx;
        full_address <= busy ? tx_base + {10'h0, texture_idx} : full_address;
        ffs <= busy ? {ffs[3:0], texture_lkp_i} : ffs;
    end
    localparam Normal = 3'b000;
    localparam Request = 3'b001;
    localparam Response = 3'b010;
    localparam Store = 3'b011;
    reg [2:0] cache_fsm = Normal;

    reg [20:0] tag [0:15];
    reg valid [0:15];
    wire [31:0] addr_select = ffs[4] ? full_address : dc_addr_i;
    wire match = tag[addr_select[10:7]]==addr_select[31:11] && valid[addr_select[10:7]];
    wire [31:0] data;
    reg [4:0] counter = 0;
    wire [3:0] wr_en = {{4{(cache_fsm==Response && tcache_d_valid)||(cache_fsm==Store && tcache_d_valid && match)}}};
    tcbram bramcache (core_clock_i, addr_select[10:2], data, wr_en, cache_fsm==Store ? dc_addr_i[10:2] : {dc_addr_i[10:7],counter}, cache_fsm==Store ? tcache_d_data : tcache_a_data);
    assign busy = (cache_fsm!=Normal)||(cache_fsm==Normal && ((ffs[4]&!match)||(dc_valid_i&&!match)));
    assign dc_data_o = data;
    always_ff @(posedge core_clock_i) begin
        case (cache_fsm)
            Normal: begin
                if (ffs[4]) begin
                    if (match) begin
                        texture_o <= data[31:8];
                        texture_valid_o <= 0;
                    end else begin
                        tcache_a_address <= full_address;
                        tcache_a_corrupt <= 0;
                        tcache_a_opcode <= 3'd4;
                        tcache_a_size <= 4'd7;
                        tcache_a_valid <= 1;
                        cache_fsm <= Response;
                    end
                end else if (dc_valid_i) begin
                    if (!match&!dc_op_i[2]) begin
                        tcache_a_address <= full_address;
                        tcache_a_corrupt <= 0;
                        tcache_a_opcode <= 3'd4;
                        tcache_a_size <= 4'd7;
                        tcache_a_valid <= 1;
                        cache_fsm <= Response;
                    end
                end
            end
            Response: begin


            end
            default: begin
                
            end
        endcase
    end

endmodule
