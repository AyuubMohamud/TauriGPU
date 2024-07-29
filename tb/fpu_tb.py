import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_fp_mul(dut):
    """Test for floating-point multiplication"""

    # Start the clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Initialize inputs
    dut.a.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.b.value = 0x3f8000  # 1.0 in IEEE 754 format
    dut.product_o.value = 0x0
    # dut.opcode.value = 0b0000

    for _ in range(10):
        await RisingEdge(dut.clk)

    # Debugging: print the values of inputs and result
    dut._log.info(f"Input a: {dut.a.value}")
    dut._log.info(f"Input b: {dut.b.value}")
    dut._log.info(f"Result: {dut.result.value}")

    # Wait more if necessary
    for cycle in range(10):
        await RisingEdge(dut.clk)
        dut._log.info(f"A at {cycle + 10} cycles: {dut.a.value}")
        dut._log.info(f"B at {cycle + 10} cycles: {dut.b.value}")
        dut._log.info(f"Result at {cycle + 10} cycles: {dut.result.value}")
        dut._log.info(f"Product at {cycle + 10} cycles: {dut.product_o.value}")
        dut._log.info(f"Product at {cycle + 10} cycles: {dut.fp_mul_0_inst.product.value}")
        dut._log.info(f"Mant1 at {cycle + 10} cycles: {dut.fp_mul_0_inst.mant1.value.integer}")
        dut._log.info(f"Mant2 at {cycle + 10} cycles: {dut.fp_mul_0_inst.mant2.value.integer}")
        dut._log.info(f"inst_a at {cycle + 10} cycles: {dut.fp_mul_0_inst.a.value}")
        dut._log.info(f"inst_b at {cycle + 10} cycles: {dut.fp_mul_0_inst.b.value}")
        dut._log.info(f"0_exp1 at {cycle + 10} cycles: {dut.fp_mul_0_inst.exp1.value}")
        dut._log.info(f"0_exp2 at {cycle + 10} cycles: {dut.fp_mul_0_inst.exp2.value}")

    expected_result = 0x3f8000  # Expected result in IEEE 754 format
    assert dut.result.value == expected_result, f"Error (fp mul): {dut.result.value} != {expected_result}"
