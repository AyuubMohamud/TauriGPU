`define GL_REPEAT 2'd0
`define GL_CLAMP 2'd1
`define GL_MIRROR 2'd2
module texCoordOps (
    input   wire logic [1:0]                texture_wrapS_mode_i,
    input   wire logic [1:0]                texture_wrapT_mode_i,
    input   wire logic [22:0]               texture_min_s_clamp_i,
    input   wire logic [22:0]               texture_max_s_clamp_i,
    input   wire logic [22:0]               texture_min_t_clamp_i,
    input   wire logic [22:0]               texture_max_t_clamp_i,

    input   wire logic [23:0]               texture_s_i,
    input   wire logic [23:0]               texture_t_i,

    output  wire logic [14:0]               s,
    output  wire logic [14:0]               t
);

    // GL_REPEAT
    // use only fractional part of coord
    wire [7:0] exponent = texture_s_i[22:15];
    wire [7:0] exponent2 = texture_t_i[22:15];
    wire [15:0] mantissa_s = exponent==0 ? 16'd0 : {1'b1,  texture_s_i[14:0]};
    wire [15:0] mantissa_t = exponent2==0 ? 16'd0 : {1'b1,  texture_t_i[14:0]};

    logic [4:0] shamt;
    always_comb begin
        case (exponent)
            8'd112: begin
                shamt = 5'd1;
            end
            8'd113: begin
                shamt = 5'd2;
            end
            8'd114: begin
                shamt = 5'd3;
            end
            8'd115: begin
                shamt = 5'd4;
            end
            8'd116: begin
                shamt = 5'd5;
            end
            8'd117: begin
                shamt = 5'd6;
            end
            8'd118: begin
                shamt = 5'd7;
            end
            8'd119: begin
                shamt = 5'd8;
            end
            8'd120: begin
                shamt = 5'd9;
            end
            8'd121: begin
                shamt = 5'd10;
            end
            8'd122: begin
                shamt = 5'd11;
            end
            8'd123: begin
                shamt = 5'd12;
            end
            8'd124: begin
                shamt = 5'd13;
            end
            8'd125: begin
                shamt = 5'd14;
            end
            8'd126: begin
                shamt = 5'd15;
            end
            8'd127: begin
                shamt = 5'd16;
            end
            8'd128: begin
                shamt = 5'd17;
            end
            8'd129: begin
                shamt = 5'd18;
            end
            8'd130: begin
                shamt = 5'd19;
            end
            8'd131: begin
                shamt = 5'd20;
            end
            8'd132: begin
                shamt = 5'd21;
            end
            8'd133: begin
                shamt = 5'd22;
            end
            8'd134: begin
                shamt = 5'd23;
            end
            8'd135: begin
                shamt = 5'd24;
            end
            8'd136: begin
                shamt = 5'd25;
            end
            8'd137: begin
                shamt = 5'd26;
            end
            8'd138: begin
                shamt = 5'd27;
            end
            8'd139: begin
                shamt = 5'd28;
            end
            8'd140: begin
                shamt = 5'd29;
            end
            8'd141: begin
                shamt = 5'd30;
            end
            8'd142: begin
                shamt = 5'd31;
            end
            default: shamt = 0;
        endcase
    end
    logic [4:0] shamt2;
    always_comb begin
        case (exponent2)
            8'd112: begin
                shamt2 = 5'd1;
            end
            8'd113: begin
                shamt2 = 5'd2;
            end
            8'd114: begin
                shamt2 = 5'd3;
            end
            8'd115: begin
                shamt2 = 5'd4;
            end
            8'd116: begin
                shamt2 = 5'd5;
            end
            8'd117: begin
                shamt2 = 5'd6;
            end
            8'd118: begin
                shamt2 = 5'd7;
            end
            8'd119: begin
                shamt2 = 5'd8;
            end
            8'd120: begin
                shamt2 = 5'd9;
            end
            8'd121: begin
                shamt2 = 5'd10;
            end
            8'd122: begin
                shamt2 = 5'd11;
            end
            8'd123: begin
                shamt2 = 5'd12;
            end
            8'd124: begin
                shamt2 = 5'd13;
            end
            8'd125: begin
                shamt2 = 5'd14;
            end
            8'd126: begin
                shamt2 = 5'd15;
            end
            8'd127: begin
                shamt2 = 5'd16;
            end
            8'd128: begin
                shamt2 = 5'd17;
            end
            8'd129: begin
                shamt2 = 5'd18;
            end
            8'd130: begin
                shamt2 = 5'd19;
            end
            8'd131: begin
                shamt2 = 5'd20;
            end
            8'd132: begin
                shamt2 = 5'd21;
            end
            8'd133: begin
                shamt2 = 5'd22;
            end
            8'd134: begin
                shamt2 = 5'd23;
            end
            8'd135: begin
                shamt2 = 5'd24;
            end
            8'd136: begin
                shamt2 = 5'd25;
            end
            8'd137: begin
                shamt2 = 5'd26;
            end
            8'd138: begin
                shamt2 = 5'd27;
            end
            8'd139: begin
                shamt2 = 5'd28;
            end
            8'd140: begin
                shamt2 = 5'd29;
            end
            8'd141: begin
                shamt2 = 5'd30;
            end
            8'd142: begin
                shamt2 = 5'd31;
            end
            default: shamt2 = 0;
        endcase
    end
    reg [31:0] container;
    always_comb begin
        if (shamt==0) begin
            container = 0;
        end else begin
            container = {16'h0, mantissa_s} << shamt;
        end
    end
    reg [31:0] container2;
    always_comb begin
        if (shamt2==0) begin
            container2 = 0;
        end else begin
            container2 = {16'h0, mantissa_t} << shamt2;
        end
    end
    wire [15:0] coord_s_abs = {1'b0, container[30:16]};
    wire [15:0] coord_t_abs = {1'b0, container2[30:16]};

    wire [15:0] flip_coord_s = ~coord_s_abs+1;
    wire [15:0] flip_coord_t = ~coord_t_abs+1;
    
    wire [14:0] GL_REPEAT_S = texture_s_i[23] ? flip_coord_s[14:0] : coord_s_abs[14:0]; // from 0-0.99997
    wire [14:0] GL_REPEAT_T = texture_t_i[23] ? flip_coord_t[14:0] : coord_t_abs[14:0]; // from 0-0.99997

    
    // For GL_CLAMP_TO_EDGE
    wire s_is_min_clamped = (texture_s_i[23])||(texture_s_i[22:15]<texture_min_s_clamp_i[22:15])||(texture_s_i[14:0]<texture_min_s_clamp_i[14:0] && (texture_s_i[22:15]==texture_min_s_clamp_i[22:15]));
    wire s_is_max_clamped = (!texture_s_i[23])&&(texture_s_i[22:15]>texture_max_s_clamp_i[22:15])||(texture_s_i[14:0]>texture_max_s_clamp_i[14:0] && (texture_s_i[22:15]==texture_max_s_clamp_i[22:15]));
    wire t_is_min_clamped = (texture_t_i[23])||(texture_t_i[22:15]<texture_min_t_clamp_i[22:15])||(texture_t_i[14:0]<texture_min_t_clamp_i[14:0] && (texture_t_i[22:15]==texture_min_t_clamp_i[22:15]));
    wire t_is_max_clamped = (!texture_t_i[23])&&(texture_t_i[22:15]>texture_max_t_clamp_i[22:15])||(texture_t_i[14:0]>texture_max_t_clamp_i[14:0] && (texture_t_i[22:15]==texture_max_t_clamp_i[22:15]));

    wire [14:0] GL_CLAMP_TO_EDGE_S = s_is_min_clamped ? 0 : s_is_max_clamped ? 15'h7FFF : coord_s_abs[14:0];
    wire [14:0] GL_CLAMP_TO_EDGE_T = t_is_min_clamped ? 0 : t_is_max_clamped ? 15'h7FFF : coord_t_abs[14:0];
    // For GL mirrored repeat
    wire [14:0] GL_MIRRORED_REPEAT_S = container[31]^texture_s_i[23] ? flip_coord_s[14:0] : coord_s_abs[14:0];
    wire [14:0] GL_MIRRORED_REPEAT_T = container2[31]^texture_t_i[23] ? flip_coord_t[14:0] : coord_t_abs[14:0];
    
    assign s = texture_wrapS_mode_i==`GL_REPEAT ? GL_REPEAT_S : texture_wrapS_mode_i==`GL_CLAMP ? GL_CLAMP_TO_EDGE_S : GL_MIRRORED_REPEAT_S;
    assign t = texture_wrapT_mode_i==`GL_REPEAT ? GL_REPEAT_T : texture_wrapT_mode_i==`GL_CLAMP ? GL_CLAMP_TO_EDGE_T : GL_MIRRORED_REPEAT_T;

endmodule
