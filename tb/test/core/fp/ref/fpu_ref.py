import struct
import math

class FPUREF:
    def float32_to_float24_bits(value: float) -> int:
        bits_32 = struct.unpack('>I', struct.pack('>f', value))[0]
        bits_24 = bits_32 >> 8
        return bits_24

    def float24_to_float32_bits(value: int) -> float:
        bits_32 = value << 8
        return struct.unpack('>f', struct.pack('>I', bits_32))[0]

    def fpu_ref(a_val, b_val, opcode):
        if opcode == 0b0000:    # Add
            return a_val + b_val
        elif opcode == 0b0100:  # Sub
            return a_val - b_val
        elif opcode == 0b0010:  # Min
            return min(a_val, b_val)
        elif opcode == 0b0001:  # Max
            return max(a_val, b_val)
        elif opcode == 0b1000:  # Floor
            return math.floor(a_val)
        elif opcode == 0b1001:  # Ceil
            return math.ceil(a_val)
        elif opcode == 0b0011:  # Mul
            return a_val * b_val
        elif opcode == 0b0101:  # Abs
            return abs(a_val)
        elif opcode == 0b0110:  # Neg
            return -a_val
        elif opcode == 0b1010:  # Sign
            return math.copysign(1.0, a_val)
        else:
            return 0.0