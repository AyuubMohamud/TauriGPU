import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_fp_add_1(dut):
    """Test for floating-point addition: 1.0 + 1.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x400000  # Expected result: 2.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp add): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_add_2(dut):
    """Test for floating-point addition: 0.5 + 2.5"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f0000  # 0.5 in IEEE 754 format
    dut.b.value = 0x402000  # 2.5 in IEEE 754 format
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x404000  # Expected result: 3.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp add): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_add_3(dut):
    """Test for floating-point addition: -1.0 + 1.0"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0xbf8000  # -1.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.result.value = 0x0

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
    assert dut.result.value == expected_result, f"Error (fp add): {dut.result.value} != {expected_result}"


@cocotb.test()
async def test_fp_add_4(dut):
    """Test for floating-point addition: 3.5 + (-2.5)"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x406000  # 3.5 in IEEE 754 format
    dut.b.value = 0xc02000  # -2.5 in IEEE 754 format
    dut.result.value = 0x0

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)

    expected_result = 0x3fc000  # Expected result: 1.0 in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp add): {dut.result.value} != {expected_result}"
