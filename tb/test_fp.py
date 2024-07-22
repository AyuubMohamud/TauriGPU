import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# @cocotb.test()
# async def test_fp_add(dut):
#     """Test for floating-point addition"""

#     dut.a.value = 0x3f8000
#     dut.b.value = 0x3f8000
#     dut.opcode.value = 0b0011

#     clock = Clock(dut.clk, 10, units="ns")
#     cocotb.start_soon(clock.start())

#     for _ in range(3):
#         await RisingEdge(dut.clk)

#     assert dut.result == 0x400000, f"Error (fp add): {dut.result.value} != 0x400000"

@cocotb.test()
async def test_fp_mul(dut):
    """Test for floating-point multiplication"""

    dut.a.value = 0x3f8000
    dut.b.value = 0x3f8000
    dut.opcode.value = 0b0000

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    for _ in range(100):
        await RisingEdge(dut.clk)

    assert dut.result == 0x3f8000, f"Error (fp mul): {dut.result.value} != 0x3f8000"