module icache_controller #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter CACHE_SIZE = 512
)(
    input wire logic clk,
    input wire logic rst,

    // Interface with core
    output logic [WIDTH - 1:0] instr,
    input logic stall, // for SFU and decode stalls
    output logic valid, // for core to know if instruction is valid
    input logic icache_flush, // for core to flush cache
    input logic [ADDR_WIDTH - 1:0] set_pc, // for core to set PC
    input logic set_pc_valid,

    // Master interface
    output logic icache_a_valid,
    input wire logic icache_a_ready,
    output logic [ADDR_WIDTH - 1:0] icache_a_addr,

    // Slave interface
    input wire logic icache_d_valid,
    input wire [WIDTH - 1:0] icache_d_data
);

    // In distributed RAM (using LUTs as RAM)
    logic valid_array[15:0];
    logic [20:0] tag_array[15:0];
    logic [4:0] counter = 0; // Remember to init set to zero otherwise Vivado make you suicide

    logic [20:0] tag;
    logic [3:0] set;
    logic [6:0] byte_offset;

    logic [ADDR_WIDTH - 1:0] pc;
    logic cache_hit;
    logic [8:0] wr_addr;

    // Extract fields from PC for each cycle
    always_comb begin
        tag = pc[31:11];
        set = pc[10:7];
        byte_offset = pc[6:0];
    end

    // Instantiate icache
    icache #(
        .WIDTH(WIDTH)
    ) icache_inst (
        .clk(clk),
        .rd_addr(pc[10:2]),
        .rd_en(icache_a_valid),
        .rd_data(instr),
        .wr_addr({pc[10:7], counter}),
        .wr_data(icache_d_data),
        .wr_en(icache_d_valid)
    );

    // No cache miss -> increment PC + 4
    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 0;
        end else if (set_pc_valid) begin
            pc <= set_pc;
        end
        else if (!stall && cache_hit) begin
            pc <= pc + 4;
        end
    end

    // Cache hit -> controller of core does not stall to push another instruction out
    always_ff @(posedge clk) begin
        if (cache_hit && !stall) begin
            valid <= 1;
        end else if (!stall) begin
            valid <= 0;
        end
    end

        // Cache hit logic
    always_comb begin
        if (tag == tag_array[set] && valid_array[set]) begin
            cache_hit = 1;
        end else begin
            cache_hit = 0;
        end
    end

    // Cache miss -> controller stalls core, fetches instruction from memory, updates cache

    localparam IDLE = 2'b00;
    localparam MISS = 2'b01;
    localparam RESPONSE = 2'b10;
    localparam CACHE_FLUSH = 2'b11;

    reg [1:0] icache_state = IDLE;

    always_ff @(posedge clk) begin
        if (rst) begin
            icache_state <= IDLE;
        end else begin
            case (icache_state)
                IDLE: begin
                    if (icache_flush) begin
                        icache_state <= CACHE_FLUSH;
                    end else if (cache_hit) begin
                        icache_state <= IDLE;
                    end else begin
                        icache_state <= MISS;
                    end
                end
                MISS: begin
                    icache_a_addr <= {pc[31:7], 7'b0};
                    icache_a_valid <= 1;
                    icache_state <= RESPONSE;
                end
                RESPONSE: begin
                    if (icache_a_ready) begin
                        icache_a_valid <= 0;
                    end
                    if (icache_d_valid) begin
                        counter <= counter + 1;
                        if (counter == 5'b11111) begin
                            valid_array[set] <= 1;
                            tag_array[set] <= tag;
                            icache_state <= IDLE;
                        end
                    end
                end
                CACHE_FLUSH: begin
                    if (counter[3:0] == 4'b1111) begin
                        icache_state <= IDLE;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                    valid_array[counter[3:0]] <= 0;
                end
            endcase
        end
    end


endmodule
