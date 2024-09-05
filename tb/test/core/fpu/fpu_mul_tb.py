import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_fp_mul_1(dut):
    """Test for floating-point multiplication"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.result.value = 0x0
    dut.opcode.value = 0b0011

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)
        # dut._log.info(f"Result at {cycle + 10} cycles: {dut.result.value}")

    expected_result = 0x3f8000  # Expected result in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp mul): {dut.result.value} != {expected_result}"

@cocotb.test()
async def test_fp_mul_2(dut):
    """Test for floating-point multiplication: 0.5 * 2.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f0000  # 0.5 in IEEE 754 format
    dut.b.value = 0x400000  # 2.0 in IEEE 754 format
    dut.result.value = 0x0
    dut.opcode.value = 0b0011

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3f8000  # Expected result: 1.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp mul): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_mul_3(dut):
    """Test for floating-point multiplication: -1.0 * 3.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0xbf8000  # -1.0 in IEEE 754 format
    dut.b.value = 0x404000  # 3.0 in IEEE 754 format
    dut.result.value = 0x0
    dut.opcode.value = 0b0011

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0xc04000  # Expected result: -3.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp mul): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_mul_4(dut):
    """Test for floating-point multiplication: 0.0 * 1.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x000000  # 0.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.result.value = 0x0
    dut.opcode.value = 0b0011

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x000000  # Expected result: 0.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp mul): {dut.result.value} != {expected_result}"
