import numpy as np

class SoftwareZBuffer:
    """
    Reference Z-buffer model that mimics external memory (DDR) usage.
    We store one-dimensional array 'memory' and do read/write by address.
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
        offset = y * self.x_res + x
        return self.base_address + offset

    def mem_read(self, addr):
        idx = addr - self.base_address
        if 0 <= idx < self.size:
            return self.memory[idx]
        else:
            # Out of range – handle as you prefer (raise error or return something)
            return 0

    def mem_write(self, addr, z_value: int):
        idx = addr - self.base_address
        if 0 <= idx < self.size:
            # Ensure z_value is non-negative and fits in z_size bits
            self.memory[idx] = max(0, z_value) & ((1 << self.z_size) - 1)

    def depth_func_pass(self, fragment_z, stored_z, func):
        if func == 0b000:   # GL_NEVER
            return False
        elif func == 0b001: # GL_LESS
            return fragment_z < stored_z
        elif func == 0b010: # GL_LEQUAL
            return fragment_z <= stored_z
        elif func == 0b011: # GL_GREATER
            return fragment_z > stored_z
        elif func == 0b100: # GL_GEQUAL
            return fragment_z >= stored_z
        elif func == 0b101: # GL_EQUAL
            return fragment_z == stored_z
        elif func == 0b110: # GL_NOTEQUAL
            return fragment_z != stored_z
        elif func == 0b111: # GL_ALWAYS
            return True
        else:
            return fragment_z < stored_z  # default GL_LESS

    def flush(self):
        self.memory.fill((1 << self.z_size) - 1)

def main():
    # Initialize z-buffer with test resolution
    x_res = 8  # Small resolution for easy testing
    y_res = 4
    z_size = 8
    base_addr = 0x1000  # Test non-zero base address
    
    zbuf = SoftwareZBuffer(x_res, y_res, z_size, base_addr)
    
    # Test 1: Basic write and read
    print("\nTest 1: Basic write/read")
    test_x, test_y = 1, 1
    test_z = 100
    addr = zbuf.addr_from_xy(test_x, test_y)
    
    print(f"Writing z={test_z} at (x={test_x}, y={test_y})")
    zbuf.mem_write(addr, test_z)
    read_z = zbuf.mem_read(addr)
    print(f"Read back z={read_z}")
    assert read_z == test_z, f"Read/write mismatch: wrote {test_z}, read {read_z}"

    # Test 2: Depth comparison functions
    print("\nTest 2: Testing depth functions")
    fragment_z = 100
    stored_z = 150
    
    print(f"Fragment Z: {fragment_z}, Stored Z: {stored_z}")
    for func in range(8):  # Test all 8 depth functions
        result = zbuf.depth_func_pass(fragment_z, stored_z, func)
        print(f"Depth func {func:03b}: {result}")

    # Test 3: Memory pattern test
    print("\nTest 3: Memory pattern test")
    # Write increasing values in a diagonal pattern
    for i in range(min(x_res, y_res)):
        addr = zbuf.addr_from_xy(i, i)
        zbuf.mem_write(addr, i * 20)
    
    # Read back and verify
    print("Diagonal pattern (should increase by 20):")
    for i in range(min(x_res, y_res)):
        addr = zbuf.addr_from_xy(i, i)
        val = zbuf.mem_read(addr)
        print(f"Position ({i},{i}): {val}")

    # Test 4: Flush operation
    print("\nTest 4: Flush operation")
    print("Before flush (showing first few values):")
    for i in range(min(4, zbuf.size)):
        print(f"Address {base_addr + i}: {zbuf.mem_read(base_addr + i)}")
    
    zbuf.flush()
    print("\nAfter flush (showing first few values):")
    max_z = (1 << z_size) - 1
    for i in range(min(4, zbuf.size)):
        val = zbuf.mem_read(base_addr + i)
        print(f"Address {base_addr + i}: {val}")
        assert val == max_z, f"Flush didn't set correct value: expected {max_z}, got {val}"

    # Test 5: Bounds checking
    print("\nTest 5: Bounds checking")
    out_of_bounds_addr = base_addr + x_res * y_res
    print(f"Reading from out of bounds address {out_of_bounds_addr}")
    val = zbuf.mem_read(out_of_bounds_addr)
    print(f"Returned value: {val}")

    # Test 6: Full frame write/read
    print("\nTest 6: Full frame write/read")
    # Write a simple depth gradient
    for y in range(y_res):
        for x in range(x_res):
            depth = (x + y) % 256  # Simple pattern
            addr = zbuf.addr_from_xy(x, y)
            zbuf.mem_write(addr, depth)
    
    print("Buffer contents:")
    for y in range(y_res):
        row = []
        for x in range(x_res):
            addr = zbuf.addr_from_xy(x, y)
            row.append(str(zbuf.mem_read(addr)).rjust(3))
        print(" ".join(row))

if __name__ == "__main__":
    main()

