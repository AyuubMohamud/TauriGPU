enum logic [1:0] {
    RGBA4444 = 2'd0,
    RGB565 = 2'd1,
    ABRG4444 = 2'd2,
    BGR565 = 2'd3
} tauri_color_types;

enum logic [2:0] {
    GL_NEVER = 3'b000,
    GL_LESS = 3'b001,
    GL_LEQUAL = 3'b010,
    GL_GREATER = 3'b011,
    GL_GEQUAL = 3'b100,
    GL_EQUAL = 3'b101,
    GL_NOTEQUAL = 3'b110,
    GL_ALWAYS = 3'b111
} tauri_zt_ops;

enum logic [2:0] {
    GL_KEEP = 3'b000,
    GL_ZERO = 3'b001,
    GL_REPLACE = 3'b010,
    GL_INCR = 3'b011,
    GL_INCR_WRAP = 3'b100,
    GL_DECR = 3'b101,
    GL_DECR_WRAP = 3'b110,
    GL_INVERT = 3'b111
} tauri_st_ops;

enum logic [0:0] {
    INT16 = 1'd0,
    FP16 = 1'd1
} tauri_tip_coord_types;

typedef struct packed {
    logic [11:0] fb_width;
    logic [11:0] fb_height;
    logic [1:0] fb_color;
} tauri_fbops_ctrl;

typedef struct packed {
    logic [31:0] fb_base_address;
} tauri_fbops_addr;

typedef struct packed {
    logic z_en;
    logic [2:0] z_op;
} tauri_zt_ctrl;

typedef struct packed {
    logic s_en;
    logic [2:0] s_op;
} tauri_st_ctrl;

typedef struct packed {
    logic [31:0] z_base_address;    
} tauri_zt_addr;

typedef struct packed {
    logic [31:0] s_base_address;    
} tauri_st_addr;

typedef struct packed {
    logic [31:0] tri_base_address;
} tauri_tip_addr;

typedef struct packed {
    logic [0:0] coord_type;
    logic [30:0] coord_len; // treated as groups of 3
} tauri_tip_ctrl;

typedef struct packed {
    logic [31:0] shader_base_addr; // start of shader instructions in GPU's native ISA.
} tauri_tsu_addr;
