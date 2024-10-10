import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_fp_sub_1(dut):
    """Test for floating-point subtraction: 2.0 - 1.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x400000  # 2.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.opcode.value = 0b0100  # Subtraction
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3f8000  # Expected result: 1.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp sub): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sub_2(dut):
    """Test for floating-point subtraction: 1.5 - 0.5"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3fc000  # 1.5 in IEEE 754 format
    dut.b.value = 0x3f0000  # 0.5 in IEEE 754 format
    dut.opcode.value = 0b0100  # Subtraction
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3f8000  # Expected result: 1.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp sub): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sub_3(dut):
    """Test for floating-point subtraction: -1.0 - (-1.0)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0xbf8000  # -1.0 in IEEE 754 format
    dut.b.value = 0xbf8000  # -1.0 in IEEE 754 format
    dut.opcode.value = 0b0100  # Subtraction
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x000000  # Expected result: 0.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp sub): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sub_4(dut):
    """Test for floating-point subtraction: 3.5 - 2.5"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x406000  # 3.5 in IEEE 754 format
    dut.b.value = 0x402000  # 2.5 in IEEE 754 format
    dut.opcode.value = 0b0100  # Subtraction
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3fc000  # Expected result: 1.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp sub): {dut.result.value} != {expected_result}"
