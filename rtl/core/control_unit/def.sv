`ifndef DEF_SV
`define DEF_SV

`define ALU_OPCODE_ADD              7'b0011000
`define ALU_OPCODE_SUB              7'b0011001
`define ALU_OPCODE_XOR              7'b0000000
`define ALU_OPCODE_AND              7'b0001000
`define ALU_OPCODE_OR               7'b0010000
`define ALU_OPCODE_MAX              7'b0100011
`define ALU_OPCODE_MAXU             7'b0100010
`define ALU_OPCODE_MIN              7'b0100001
`define ALU_OPCODE_MINU             7'b0100000
`define ALU_OPCODE_LSL              7'b0101001
`define ALU_OPCODE_LSR              7'b0101000
`define ALU_OPCODE_ASR              7'b0101010
`define ALU_OPCODE_BEQ              7'b1000100
`define ALU_OPCODE_BNE              7'b1000110
`define ALU_OPCODE_BLT              7'b1000011
`define ALU_OPCODE_BGE              7'b1000001
`define ALU_OPCODE_BLTU             7'b1000010
`define ALU_OPCODE_BGEU             7'b1000000

`define FPU_OPCODE_FADD             4'b0000
`define FPU_OPCODE_FSUB             4'b0100
`define FPU_OPCODE_FMAX             4'b0001
`define FPU_OPCODE_FMIN             4'b0010
`define FPU_OPCODE_FMUL             4'b0011
`define FPU_OPCODE_FABS             4'b0101
`define FPU_OPCODE_FNEG             4'b0110
`define FPU_OPCODE_FFLOOR           4'b1000
`define FPU_OPCODE_FCEIL            4'b1001
`define FPU_OPCODE_FSIGN            4'b1010

`define SFU_OPCODE_RSQRT            3'b000
`define SFU_OPCODE_RECIP            3'b001
`define SFU_OPCODE_LOG2             3'b100
`define SFU_OPCODE_EXP              3'b101
`define SFU_OPCODE_SIN              3'b110
`define SFU_OPCODE_ATAN             3'b111

`endif
