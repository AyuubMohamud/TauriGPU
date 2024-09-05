import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_fp_sign_1(dut):
    """Test for floating-point sign: sign(1.0)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.opcode.value = 0b1010  # Sign operation
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait for the result to stabilize
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3f8000  # Expected result: 1.0 in IEEE 754 format (representing positive)
    assert dut.result.value == expected_result, f"Error (fp sign): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sign_2(dut):
    """Test for floating-point sign: sign(-1.5)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0xbfc000  # -1.5 in IEEE 754 format
    dut.opcode.value = 0b1010  # Sign operation
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait for the result to stabilize
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0xbf8000  # Expected result: -1.0 in IEEE 754 format (representing negative)
    assert dut.result.value == expected_result, f"Error (fp sign): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sign_3(dut):
    """Test for floating-point sign: sign(0.0)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x000000  # 0.0 in IEEE 754 format
    dut.opcode.value = 0b1010  # Sign operation
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait for the result to stabilize
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x000000  # Expected result: 0.0 in IEEE 754 format (representing zero)
    assert dut.result.value == expected_result, f"Error (fp sign): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sign_4(dut):
    """Test for floating-point sign: sign(-Infinity)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0xff8000  # -Infinity in IEEE 754 format
    dut.opcode.value = 0b1010  # Sign operation
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait for the result to stabilize
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0xbf8000  # Expected result: -1.0 in IEEE 754 format (representing negative)
    assert dut.result.value == expected_result, f"Error (fp sign): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_sign_5(dut):
    """Test for floating-point sign: sign(+Infinity)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x7f8000  # +Infinity in IEEE 754 format
    dut.opcode.value = 0b1010  # Sign operation
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Opcode: {dut.opcode.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait for the result to stabilize
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3f8000  # Expected result: 1.0 in IEEE 754 format (representing positive)
    assert dut.result.value == expected_result, f"Error (fp sign): {dut.result.value} != {expected_result}"
