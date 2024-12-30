import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import random
import numpy as np

from ref_model.z_buffer_ref import SoftwareZBuffer

@cocotb.test()
async def test_new_z_buffer(dut):

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.start_i.value = 0
    dut.flush_i.value = 0
    dut.pixel_x_i.value = 0
    dut.pixel_y_i.value = 0
    dut.pixel_z_i.value = 0
    dut.z_depth_func_i.value = 0
    dut.buffer_base_address_i = 0

    await RisingEdge(dut.clk)

    # Init buffer model
    x_res = dut.X_RES.value
    y_res = dut.Y_RES.value
    z_size = dut.Z_SIZE.value
    base_addr = dut.buffer_base_address_i.value

    szbuf = SoftwareZBuffer(x_res, y_res, z_size, base_addr)
    mismatches = 0

    num_tests = 1000
    for i in tqdm(range(num_tests), desc="ZBuffer Tests"):
        px = random.randint(0, x_res - 1)
        py = random.randint(0, y_res - 1)
        pz = random.randint(0, (1 << z_size) - 1)
        z_func = random.randint(0, 7)

        dut.pixel_x_i = px
        dut.pixel_y_i = py
        dut.pixel_z_i = pz
        dut.z_depth_func_i = z_func

        dut.start_i.value = 1
        await RisingEdge(dut.clk)
        dut.start_i.value = 0

        for _ in range(10):
            await RisingEdge(dut.clk)
        
        addr = szbuf.addr_from_xy(px, py)
        ref_z = szbuf.mem_read(addr)
        dut_z = dut.z_buffer_o.value
        pass_ref = szbuf.depth_func_pass(pz, ref_z, z_func)
        pass_dut = dut_z == 1
        if pass_ref:
            szbuf.mem_write(addr, pz)

        if ref_z != dut_z:
            print(f"Test failed at {px}, {py} with z_func {z_func}: ref={ref_z}, dut={dut_z}")
            print(f"pass_ref={pass_ref}, pass_dut={pass_dut}")
            mismatches += 1

        # Test flush
        dut.flush_i.value = 1
        await RisingEdge(dut.clk)
        dut.flush_i.value = 0

        for _ in range(10):
            await RisingEdge(dut.clk)
        
        for addr in range(base_addr, base_addr + szbuf.size):
            if szbuf.mem_read(addr) != (1 << z_size) - 1:
                print(f"Flush test failed at address {addr}")
                mismatches += 1
        
    assert mismatches == 0, f"Test failed with {mismatches} mismatches"
