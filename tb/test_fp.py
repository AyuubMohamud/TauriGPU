import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

@cocotb.test()
async def fp_test_add(dut):
    """Test for floating point addition"""

    A = 0.1
    B = 0.2

    dut.a <= A
    dut.B <= B

    await Timer(2, units='ns')

    assert dut.result == 0.3, f"Error (fp add): {dut.result} != 0.3"

@cocotb.test()
async def fp_test_sub(dut):
    """Test for floating point subtraction"""

    A = 0.2
    B = 0.1

    dut.a <= A
    dut.B <= B

    await Timer(2, units='ns')

    assert dut.result == 0.1, f"Error (fp sub): {dut.result} != 0.1"