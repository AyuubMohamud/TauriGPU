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
    dut.data_w_ready.value = 0  # Start with write ready deasserted
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

    # Counters and tracking
    mismatches = 0
    num_tests = 1000
    flush_probability = 0.1  # 10% chance of flush between tests
    times_of_flushes = 0  # Track number of flush operations
    flush_tests = []  # Track which test indices were flushes

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

        # Read old_z from hardware buffer before the update
        old_hw_z = mem_buf.mem_read(addr)

        # Evaluate pass_ref using old_z (the old stored Z)
        pass_ref = szbuf.depth_func_pass(pz, old_z, z_func)

        # Update the software reference model
        szbuf.mem_write(addr, pz, z_func)

        # Start the DUT operation
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Keep running until DUT is done
        while not dut.done_o.value:

            ''' Debugging signals for handshake signals '''
            # print(f"Read Ready = {dut.data_r_ready.value}, Read Valid = {dut.data_r_valid.value}")
            # print(f"Write Ready = {dut.data_w_ready.value}, Write Valid = {dut.data_w_valid.value}\n")
            # print(f"State = {state_dict[int(dut.curr_state.value)]}")
            # print(f"DUT Depth Pass = {bool(dut.depth_pass_o.value)}")
            # print(f"DUT depth_comparison_result = {bool(dut.depth_comparison_result.value)}\n")
            
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
            if dut.data_w_valid.value:
                # print(f"DUT has requested write at address {dut.buf_addr.value}")
                # Acknowledge write request
                dut.data_w_ready.value = 1
                await RisingEdge(dut.clk_i)
                dut.data_w_ready.value = 0  # Deassert after one cycle
                # Perform the write
                hw_addr = dut.buf_addr.value
                data_to_write = dut.buf_data_w.value
                mem_buf.mem_write(hw_addr, data_to_write)

        # Compare final hardware memory vs. software reference
        hw_z = mem_buf.mem_read(addr)
        ref_z = szbuf.mem_read(addr)

        if hw_z != ref_z:
            mismatches += 1
            print("----------------------------------------")
            # Check if previous test was a flush
            prev_was_flush = (i > 0) and ((i-1) in flush_tests)
            print(f"Previous test was {'a flush' if prev_was_flush else 'not a flush'}")
            
            # Print current state information
            print(f"Current state: {state_dict[int(dut.curr_state.value)]}")
            print(f"Flush done: {dut.flush_done_o.value}")
            print(f"Start signal: {dut.start_i.value}")
            print(f"Done signal: {dut.done_o.value}")
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
            print(f"old dut_z = {old_hw_z}  (hw model before update)")
            print(f"old_z     = {old_z}  (ref model before update)")
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

        ''' RANDOM FLUSH OPERATION '''
        # Only allow flush if previous operation wasn't a flush
        if (i > num_tests * 0.1 and 
            random.random() < flush_probability and
            not dut.flush_done_o.value):
            # Start flush operation
            dut.flush_i.value = 1
            dut.start_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.start_i.value = 0
            
            # Wait for flush to complete with debug logging
            flush_cycles = 0
            
            while not dut.flush_done_o.value:
                await RisingEdge(dut.clk_i)
                flush_cycles += 1
                
                # ''' Debugging signals for flush operation '''
                # print(f"\nFlush cycle {flush_cycles}, state = {state_dict[int(dut.curr_state.value)]}")
                # print("MemoryBuffer State during flush:")
                # for yy in range(y_res):
                #     row_start = yy * x_res
                #     row_values = mem_buf.memory[row_start : row_start + x_res]
                #     print(f"Row {yy}: {row_values}")
                
                # print(f"dut.buf_addr = {int(dut.buf_addr.value)}")
                # print(f"flush counter = {int(dut.flush_counter.value)}")
                # print(f"Write Valid = {dut.data_w_valid.value}, Write Ready = {dut.data_w_ready.value}")
                
                # print(f"Current address: {int(dut.buf_addr.value)}")
                # print(f"data_w_valid: {dut.data_w_valid.value}")
                # print(f"data_w_ready: {dut.data_w_ready.value}")
                # print(f"flush_done_o: {dut.flush_done_o.value}")
                # print(f"X_RES*Y_RES = {dut.X_RES.value * dut.Y_RES.value}")
                
                if dut.data_w_valid.value:
                    # print(f"DUT has requested write at address {int(dut.buf_addr.value)}")
                    # Acknowledge write request
                    dut.data_w_ready.value = 1
                    await RisingEdge(dut.clk_i)
                    # print(f"data_w_ready: {dut.data_w_ready.value}")
                    dut.data_w_ready.value = 0  # Deassert after one cycle
                    # Perform the write
                    hw_addr = dut.buf_addr.value
                    data_to_write = dut.buf_data_w.value
                    mem_buf.mem_write(hw_addr, data_to_write)
                
                # Timeout check
                if flush_cycles > 20:  # Adjust timeout as needed
                    print("\nFlush operation timed out!")
                    print("Final MemoryBuffer State:")
                    for yy in range(y_res):
                        row_start = yy * x_res
                        row_values = mem_buf.memory[row_start : row_start + x_res]
                        print(f"Row {yy}: {row_values}")
                    assert False, f"Flush operation timed out after {flush_cycles} cycles (total flushes so far: {times_of_flushes})"
            
            # Verify flush completed correctly
            flush_errors = 0
            for addr in range(x_res * y_res):
                hw_z = mem_buf.mem_read(addr)
                if hw_z != (1 << z_size) - 1:
                    print(f"Flush verification failed at addr {addr}: got {hw_z} expected {(1 << z_size) - 1}")
                    flush_errors += 1
            assert flush_errors == 0, f"Flush failed at {flush_errors} addresses"
            
            # Reset flush signal and wait for DUT to return to IDLE
            dut.flush_i.value = 0
            while dut.curr_state.value != 0:  # Wait until back in IDLE state
                await RisingEdge(dut.clk_i) #! This is a blocking wait - crucial for correct operation, expect the DRAM to act the same
            
            # Also flush the reference model
            szbuf.flush()
            times_of_flushes += 1
            flush_tests.append(i)  # Record this test index as a flush
            
            # Debug print flush completion
            # print(f"\nFlush completed at test {i}, total flushes: {times_of_flushes}")
            # print("MemoryBuffer after flush:")
            # for yy in range(y_res):
            #     row_start = yy * x_res
            #     row_values = mem_buf.memory[row_start : row_start + x_res]
            #     print(f"Row {yy}: {row_values}")


    # Final test result
    print(f"Test completed with {times_of_flushes} flush operations.")
    assert mismatches == 0, f"Test failed with {mismatches} mismatches out of {num_tests} tests."
