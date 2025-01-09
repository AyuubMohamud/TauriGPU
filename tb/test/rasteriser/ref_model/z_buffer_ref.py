import numpy as np
from cocotb.handle import BinaryValue  # Import BinaryValue for type checking

class MemoryBuffer:
    """
    Memory buffer that the hardware interacts with.
    """

    def __init__(self, size, z_size):
        self.size = size
        self.z_size = z_size
        self.memory = np.full(self.size, (1 << z_size) - 1, dtype=np.uint32)

    def mem_read(self, addr):
        """
        Read the z-value from the specified address.
        """
        # Convert BinaryValue to integer if needed
        if isinstance(addr, BinaryValue):
            addr_int = addr.integer
        else:
            addr_int = int(addr)

        if 0 <= addr_int < self.size:
            return self.memory[addr_int]
        else:
            raise ValueError(f"Address {addr_int} is out of bounds.")

    def mem_write(self, addr, z_value):
        """
        Write the z-value to the specified address.
        """
        # Convert BinaryValue to integer if needed
        if isinstance(addr, BinaryValue):
            addr_int = addr.integer
        else:
            addr_int = int(addr)

        if 0 <= addr_int < self.size:
            # Convert BinaryValue to integer if needed
            if isinstance(z_value, BinaryValue):
                z_int = z_value.integer
            else:
                z_int = int(z_value)
            # Ensure z_value is non-negative and fits in z_size bits
            self.memory[addr_int] = max(0, z_int) & ((1 << self.z_size) - 1)
        else:
            raise ValueError(f"Address {addr_int} is out of bounds.")

    def flush(self):
        """
        Reset the entire buffer to the maximum depth value.
        """
        self.memory.fill((1 << self.z_size) - 1)

class SoftwareZBuffer:
    """
    Reference Z-buffer model that maintains the "correct" state of the Z-buffer.
    """

    def __init__(self, x_res, y_res, z_size, base_address=0):
        self.x_res = x_res
        self.y_res = y_res
        self.z_size = z_size
        self.base_address = base_address

        self.size = x_res * y_res
        # For simplicity, store each z as an int in a 1D array:
        self.memory = np.full(self.size, (1 << z_size) - 1, dtype=np.uint32)

    def addr_from_xy(self, x, y):
        """
        Calculate the memory address from pixel coordinates (x, y).
        """
        offset = y * self.x_res + x
        return self.base_address + offset

    def mem_read(self, addr):
        """
        Read the z-value from the specified address.
        """
        idx = addr - self.base_address
        if 0 <= idx < self.size:
            return self.memory[idx]
        else:
            raise ValueError(f"Address {addr} is out of bounds.")

    def mem_write(self, addr, z_value, z_func):
        """
        Write the z-value to the specified address.
        Args:
            addr: Memory address to write to
            z_value: Z value to write
            z_func: Depth function to use for comparison (e.g., GL_LESS)
        """
        idx = addr - self.base_address
        if 0 <= idx < self.size:
            if isinstance(z_value, BinaryValue):
                z_int = z_value.integer
            else:
                z_int = int(z_value)
            
            # Get current value and perform depth test before writing
            curr_z = self.memory[idx]
            if self.depth_func_pass(z_int, curr_z, z_func):
                self.memory[idx] = max(0, z_int) & ((1 << self.z_size) - 1)
        else:
            raise ValueError(f"Address {addr} is out of bounds.")

    def depth_func_pass(self, fragment_z, stored_z, func):
        """
        Determine if the fragment passes the depth test based on the depth function.
        """
        # Convert BinaryValue to integer if needed
        if isinstance(fragment_z, BinaryValue):
            frag_z = fragment_z.integer
        else:
            frag_z = int(fragment_z)

        if isinstance(stored_z, BinaryValue):
            stor_z = stored_z.integer
        else:
            stor_z = int(stored_z)

        # Define depth function logic - no change needed here actually
        depth_funcs = {
            0b000: lambda f, s: False,       # GL_NEVER
            0b001: lambda f, s: f < s,       # GL_LESS
            0b010: lambda f, s: f <= s,      # GL_LEQUAL
            0b011: lambda f, s: f > s,       # GL_GREATER
            0b100: lambda f, s: f >= s,      # GL_GEQUAL
            0b101: lambda f, s: f == s,      # GL_EQUAL
            0b110: lambda f, s: f != s,      # GL_NOTEQUAL
            0b111: lambda f, s: True,        # GL_ALWAYS
        }

        # Get the comparison function or default to GL_LESS
        compare = depth_funcs.get(func, lambda f, s: f < s)
        return compare(frag_z, stor_z)

    def flush(self):
        """
        Reset the entire Z-buffer to the maximum depth value.
        """
        self.memory.fill((1 << self.z_size) - 1)