import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np

from mods.logging_mods import *
from mods.quantization_mods import *

class SoftwareZBuffer:
    def __init__(self, x_res, y_res, z_size):
        self.x_res = x_res
        self.y_res = y_res
        self.z_size = z_size
        self.buffer = np.full((x_res, y_res), (1 << z_size) - 1, dtype=np.uint32)

    def test_depth(self, x, y, z, func):
        current_z = self.buffer[x, y]
        if func == 0b000:  # GL_NEVER
            return False
        elif func == 0b001:  # GL_LESS
            return z < current_z
        elif func == 0b010:  # GL_LEQUAL
            return z <= current_z
        elif func == 0b011:  # GL_GREATER
            return z > current_z
        elif func == 0b100:  # GL_GEQUAL
            return z >= current_z
        elif func == 0b101:  # GL_EQUAL
            return z == current_z
        elif func == 0b110:  # GL_NOTEQUAL
            return z != current_z
        elif func == 0b111:  # GL_ALWAYS
            return True
        else:
            return z < current_z  # Default to GL_LESS

    def update(self, x, y, z):
        self.buffer[x, y] = z

    def flush(self):
        self.buffer.fill((1 << self.z_size) - 1)

@cocotb.test()
async def test_z_buffer(dut):
    """Randomized testing for the Z-buffer module"""

    test_iters = 1000
    color_log(dut, f'Running test_z_buffer() with test_iters = {test_iters}')

    # Read parameters from DUT
    Z_SIZE = int(dut.Z_SIZE.value)
    X_RES = int(dut.X_RES.value)
    Y_RES = int(dut.Y_RES.value)

    # Initialize software z-buffer
    sw_z_buffer = SoftwareZBuffer(X_RES, Y_RES, Z_SIZE)

    # Start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    # Reset DUT
    dut.start_i.value = 0
    dut.flush_i.value = 0
    dut.pixel_x_i.value = 0
    dut.pixel_y_i.value = 0
    dut.pixel_z_i.value = 0
    dut.z_depth_func_i.value = 0
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)

    # Test different depth functions
    z_depth_funcs = {
        "GL_NEVER": 0b000,
        "GL_LESS": 0b001,
        "GL_LEQUAL": 0b010,
        "GL_GREATER": 0b011,
        "GL_GEQUAL": 0b100,
        "GL_EQUAL": 0b101,
        "GL_NOTEQUAL": 0b110,
        "GL_ALWAYS": 0b111,
    }

    for test_count in tqdm(range(test_iters)):
        # Generate random test case
        pixel_x = np.random.randint(0, X_RES)
        pixel_y = np.random.randint(0, Y_RES)
        pixel_z = np.random.randint(0, 1 << Z_SIZE)
        z_depth_func = np.random.choice(list(z_depth_funcs.values()))

        # Apply inputs to DUT
        dut.start_i.value = 1
        dut.pixel_x_i.value = int(pixel_x)
        dut.pixel_y_i.value = int(pixel_y)
        dut.pixel_z_i.value = int(pixel_z)
        dut.z_depth_func_i.value = int(z_depth_func)

        # Wait for DUT to process
        await RisingEdge(dut.clk_i)
        await RisingEdge(dut.clk_i)

        # Read DUT output
        depth_pass_dut = bool(dut.depth_pass_o.value)

        # Compute expected result using software z-buffer
        depth_pass_sw = sw_z_buffer.test_depth(pixel_x, pixel_y, pixel_z, z_depth_func)

        # Compare results
        if depth_pass_dut != depth_pass_sw:
            color_log(dut, f'\n\n===== Iter {test_count} =====', log_error=True)
            color_log(dut, f'Input pixel_x: {pixel_x}')
            color_log(dut, f'Input pixel_y: {pixel_y}')
            color_log(dut, f'Input pixel_z: {pixel_z}')
            color_log(dut, f'Input z_depth_func: {bin(z_depth_func)}')
            color_log(dut, f'')
            color_log(dut, f'DUT depth_pass: {depth_pass_dut}', log_error=True)
            color_log(dut, f'Expected depth_pass: {depth_pass_sw}', log_error=True)
            assert False, "Mismatch between DUT and software z-buffer"

        # Update software z-buffer if depth test passed
        if depth_pass_sw:
            sw_z_buffer.update(pixel_x, pixel_y, pixel_z)

        # Occasionally test flushing
        if np.random.random() < 0.01:  # 1% chance to flush
            dut.flush_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.flush_i.value = 0
            await RisingEdge(dut.clk_i)
            sw_z_buffer.flush()

    color_log(dut, f'\nZ-buffer test completed successfully for {test_iters} iterations.')