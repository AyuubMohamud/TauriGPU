import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import random
import numpy as np

# Make sure these imports match your actual file locations/names
from ref_model.z_buffer_ref import SoftwareZBuffer, MemoryBuffer

# Add flush method to SoftwareZBuffer
def flush(self):
    """Fill the entire buffer with maximum depth values"""
    self.memory = [(1 << self.z_size) - 1] * (self.x_res * self.y_res)

SoftwareZBuffer.flush = flush

@cocotb.test()
async def test_new_z_buffer(dut):
    """
    Test the Z-Buffer module by comparing against a reference software model.
    We fix the depth comparison logging by checking pass_ref against the *old*
    stored Z value, before we do the software model's write.
    """
    # Create a clock on clk_i at 10ns period
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.start_i.value = 0
    dut.flush_i.value = 0
    dut.pixel_x_i.value = 0
    dut.pixel_y_i.value = 0
    dut.pixel_z_i.value = 0
    dut.z_depth_func_i.value = 0
    dut.buffer_base_address_i.value = 0

    # Initialize handshake signals
    dut.data_r_valid.value = 0
    dut.data_w_ready.value = 1  # Always ready to accept writes
    dut.buf_data_r.value = 0

    # Wait one rising edge for stable reset conditions
    await RisingEdge(dut.clk_i)

    # Set up reference models
    x_res = dut.X_RES.value
    y_res = dut.Y_RES.value
    z_size = dut.Z_SIZE.value
    base_addr = dut.buffer_base_address_i.value

    # Software Z-buffer and memory buffer
    szbuf = SoftwareZBuffer(x_res, y_res, z_size, base_addr)
    mem_buf = MemoryBuffer(x_res * y_res, z_size)

    # Counters
    mismatches = 0
    num_tests = 8000
    flush_probability = 0.1  # 10% chance of flush between tests

    state_dict = {
        0: "IDLE",
        1: "READ",
        2: "WRITE",
        3: "RENDER_DONE",
        4: "FLUSH",
        5: "DONE"
    }

    for i in tqdm(range(num_tests), desc="ZBuffer Tests"):
        # Generate random test values
        px = random.randint(0, x_res - 1)
        py = random.randint(0, y_res - 1)
        pz = random.randint(0, (1 << z_size) - 1)
        # Test all depth functions in sequence
        z_func = random.randint(0, 7)

        # Set DUT inputs
        dut.pixel_x_i.value = px
        dut.pixel_y_i.value = py
        dut.pixel_z_i.value = pz
        dut.z_depth_func_i.value = z_func

        # Calculate address
        addr = szbuf.addr_from_xy(px, py)

        # Read old_z from reference model before the update
        old_z = szbuf.mem_read(addr)

        # Evaluate pass_ref using old_z (the old stored Z)
        pass_ref = szbuf.depth_func_pass(pz, old_z, z_func)

        # Update the software reference model
        szbuf.mem_write(addr, pz, z_func)

        # Randomly decide whether to flush before this test
        if random.random() < flush_probability:
            # Start flush operation
            dut.flush_i.value = 1
            dut.start_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.start_i.value = 0
            
            # Wait for flush to complete
            while not dut.flush_done_o.value:
                await RisingEdge(dut.clk_i)
            
            # Verify flush completed correctly
            for addr in range(x_res * y_res):
                hw_z = mem_buf.mem_read(addr)
                assert hw_z == (1 << z_size) - 1, f"Flush failed at address {addr}, got {hw_z} instead of max value"
            
            # Reset flush signal
            dut.flush_i.value = 0
            await RisingEdge(dut.clk_i)
            
            # Also flush the reference model
            szbuf.flush()
        
        # Start the DUT operation
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Keep running until DUT is done
        while not dut.done_o.value:

            ''' Logging for handshake signals debugging '''

            # print(f"Read Ready = {dut.data_r_ready.value}, Read Valid = {dut.data_r_valid.value}")
            # print(f"Write Ready = {dut.data_w_ready.value}, Write Valid = {dut.data_w_valid.value}\n")

            # print(f"State = {state_dict[int(dut.curr_state.value)]}")
            # print(f"DUT Depth Pass = {bool(dut.depth_pass_o.value)}")
            # print(f"DUT depth_comparison_result = {bool(dut.depth_comparison_result.value)}\n")
            
            ''' End of logging '''

            # If DUT wants to read from memory
            if dut.data_r_ready.value:
                # print(f"DUT has requested read at address {dut.buf_addr.value}")
                hw_addr = dut.buf_addr.value
                # Provide data from MemoryBuffer
                dut.buf_data_r.value = int(mem_buf.mem_read(hw_addr))
                # Signal that data_r is valid for this cycle
                dut.data_r_valid.value = 1
                await RisingEdge(dut.clk_i)
                # Deassert after one cycle
                dut.data_r_valid.value = 0
            else:
                await RisingEdge(dut.clk_i)

            # If DUT wants to write to memory
            if dut.data_w_valid.value and dut.data_w_ready.value:
                # print(f"DUT has requested write at address {dut.buf_addr.value}")
                hw_addr = dut.buf_addr.value
                data_to_write = dut.buf_data_w.value
                mem_buf.mem_write(hw_addr, data_to_write)

        # Compare final hardware memory vs. software reference
        hw_z = mem_buf.mem_read(addr)
        ref_z = szbuf.mem_read(addr)

        if hw_z != ref_z:
            mismatches += 1
            print("----------------------------------------")
            # Map depth function to OpenGL enum name
            depth_func_names = {
                0: "GL_NEVER",
                1: "GL_LESS",
                2: "GL_LEQUAL",
                3: "GL_GREATER",
                4: "GL_GEQUAL",
                5: "GL_EQUAL",
                6: "GL_NOTEQUAL",
                7: "GL_ALWAYS"
            }
            print(f"Test {i + 1} failed at (x, y) = ({px}, {py}) with depth function = {depth_func_names[z_func]}")
            print("----------------------------------------")
            print(f"input_z   = {pz}")
            print(f"old_z     = {old_z}  (before update)")
            print(f"pass_ref  = {pass_ref}, pass_dut = {bool(dut.depth_pass_o.value)}")
            print(f"hw_buf_z  = {hw_z}")
            print(f"ref_buf_z = {ref_z}")

            print("\nMemoryBuffer State:")
            for yy in range(y_res):
                row_start = yy * x_res
                row_values = mem_buf.memory[row_start : row_start + x_res]
                print(f"Row {yy}: {row_values}")

            print("\nSoftwareZBuffer State:")
            for yy in range(y_res):
                row_start = yy * x_res
                row_values = szbuf.memory[row_start : row_start + x_res]
                print(f"Row {yy}: {row_values}")
            print("----------------------------------------")

    # Final test result
    assert mismatches == 0, f"Test failed with {mismatches} mismatches out of {num_tests} tests."
