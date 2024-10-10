import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np
import sys

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

    # Redirect output to log.txt
    log_file = open('log.txt', 'w')
    sys.stdout = log_file

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

    states = {
        0: "IDLE",
        1: "RENDER",
        2: "FLUSH",
        3: "DONE",
    }

    for _ in range(10):
        await RisingEdge(dut.clk_i)

    iter_255 = []
    flush = []
    mismatch = {}

    for test_count in tqdm(range(test_iters)):
        # Generate random test case
        pixel_x = np.random.randint(0, X_RES)
        pixel_y = np.random.randint(0, Y_RES)
        pixel_z = np.random.randint(0, 1 << Z_SIZE)
        z_depth_func = np.random.choice(list(z_depth_funcs.values()))
        # z_depth_func = 0b001 # test GL_LESS only

        print('----------------------------------')
        print(f'Iteration: {test_count}')
        print('----------------------------------')
        print(f'pixel_x: {pixel_x}')
        print(f'pixel_y: {pixel_y}')
        print(f'sw buffer value: {sw_z_buffer.buffer[pixel_x, pixel_y]}')
        print(f'corresponding z_depth_func: {list(z_depth_funcs.keys())[list(z_depth_funcs.values()).index(z_depth_func)]}')
        print('----------------')

        if (dut.curr_buffer_z.value == 255):
            color_log(dut, f'THE HW BUFFER IS AT 255!!!')
            iter_255.append(test_count)

        # Apply inputs to DUT
        dut.start_i.value = 1
        dut.pixel_x_i.value = int(pixel_x)
        dut.pixel_y_i.value = int(pixel_y)
        dut.pixel_z_i.value = int(pixel_z)
        dut.z_depth_func_i.value = int(z_depth_func)

        await RisingEdge(dut.clk_i)

        print(f'hw buffer value: {int(dut.curr_buffer_z.value)}')
        print(f'pixel_z_i: {int(dut.pixel_z_i.value)}')
        print(f'start_i: {int(dut.start_i.value)}')
        print('----------------')

        # Read DUT output
        depth_pass_dut = bool(dut.depth_pass_o.value)
        print(f'depth_pass_o: {depth_pass_dut}')

        # Compute expected result using software z-buffer
        depth_pass_sw = sw_z_buffer.test_depth(pixel_x, pixel_y, pixel_z, z_depth_func)
        print(f'depth_pass_sw: {depth_pass_sw}')

        # Other signals
        curr_state = int(dut.curr_state.value)
        print(f'curr_state: {states.get(curr_state, "UNKNOWN")}')

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

            color_log(dut, f'Iterations where HW buffer was 255: {iter_255}')
            color_log(dut, f'Iterations where flush was called: {flush}')
            color_log(dut, f'Iterations where mismatch occurred: {mismatch}')

            assert False, "Mismatch between DUT and software z-buffer"

        # Update software z-buffer if depth test passed
        if depth_pass_sw:
            sw_z_buffer.update(pixel_x, pixel_y, pixel_z)
            print(f'Updated sw buffer value at {pixel_x}, {pixel_y} to {sw_z_buffer.buffer[pixel_x, pixel_y]}')

        print(f'current hw buffer value: {int(dut.curr_buffer_z.value)}')

        # Occasionally test flushing
        if np.random.random() < 0.01:  # 1% chance of flush
            color_log(dut, f'Flushing the z-buffer...')
            dut.flush_i.value = 1
            sw_z_buffer.flush()
            flush.append(test_count)

            while dut.flush_done_o.value == 0:
                await RisingEdge(dut.clk_i)
                curr_state = int(dut.curr_state.value)
                print(f'curr_state: {states.get(curr_state, "UNKNOWN")}')
            
            if dut.flush_done_o.value == 1:
                dut.flush_i.value = 0
                print(f'Flush done')

        while dut.done_o.value == 0:
            await RisingEdge(dut.clk_i)
            curr_state = int(dut.curr_state.value)
            print(f'curr_state: {states.get(curr_state, "UNKNOWN")}')
            print(f'Update complete: {int(dut.update_complete.value)}')
            print(f'Depth_pass_o: {int(dut.depth_pass_o.value)}')
        
        print(f'current hw buffer value: {int(dut.curr_buffer_z.value)}')
        print(f'current sw buffer value: {sw_z_buffer.buffer[pixel_x, pixel_y]}')

        if (int(dut.curr_buffer_z.value) != sw_z_buffer.buffer[pixel_x, pixel_y]):
            # assert False, "Mismatch between DUT and software z-buffer"
            mismatch[test_count] = (pixel_x, pixel_y)


    color_log(dut, f'\nZ-buffer test completed successfully for {test_iters} iterations.')
    color_log(dut, f'Iterations where HW buffer was 255: {iter_255}')
    color_log(dut, f'Iterations where flush was called: {flush}')

    log_file.close()