import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np
from tqdm import tqdm

from ref.fpu_ref import FPUREF

@cocotb.test()
async def test_fpu_operations(dut):
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    for _ in range(5):
        await RisingEdge(dut.clk)

    test_ranges = {
        "range_1": np.arange(-256, 256, 5,       dtype='f'),
        "range_2": np.arange(-256, 256, 1/8,     dtype='f'),
        "range_3": np.arange(-256, 256, 1/1024,  dtype='f'),
    }

    opcodes_to_test = [
        0b0000,  # Add
        0b0100,  # Sub
        0b0010,  # Min
        0b0001,  # Max
        0b1000,  # Floor
        0b1001,  # Ceil
        0b0011,  # Mul
        0b0101,  # Abs
        0b0110,  # Neg
        0b1010,  # Sign
    ]

    single_operand_ops = {0b1000, 0b1001, 0b0101, 0b0110, 0b1010}
    mismatch_count = 0
    total_tests = 0
    max_tests_per_range = 10

    # Calculate total number of tests for progress bar
    for range_name, values in test_ranges.items():
        if len(values) > max_tests_per_range:
            values = values[:max_tests_per_range]
        for opcode in opcodes_to_test:
            if opcode in single_operand_ops:
                total_tests += len(values)
            else:
                total_tests += len(values) * len(values)

    with tqdm(total=total_tests, desc="FPU Tests") as pbar:
        for range_name, values in test_ranges.items():
            if len(values) > max_tests_per_range:
                idx = np.linspace(0, len(values) - 1, max_tests_per_range).astype(int)
                values = values[idx]

            for opcode in opcodes_to_test:
                for a_float in values:
                    if opcode in single_operand_ops:
                        b_values = [0.0]  # Only test with one b value for single operand ops
                    else:
                        b_values = values

                    for b_float in b_values:
                        dut.a.value = 0
                        dut.b.value = 0
                        dut.opcode.value = 0
                        dut.result.value = 0

                        await Timer(1, units="ns")

                        dut.a.value = FPUREF.float32_to_float24_bits(a_float)
                        dut.b.value = FPUREF.float32_to_float24_bits(b_float)
                        dut.opcode.value = opcode

                        await Timer(1, units="ns")

                        for _ in range(5):
                            await RisingEdge(dut.clk)

                        hw_raw = dut.result.value.integer
                        hw_val = FPUREF.float24_to_float32_bits(hw_raw)

                        ref_val = FPUREF.fpu_ref(a_float, b_float, opcode)

                        diff = abs(hw_val - ref_val)
                        TOL = 2
                        if diff > TOL:
                            mismatch_count += 1
                            dut._log.warning(
                                f"[{range_name}] opcode={bin(opcode)} | "
                                f"a={a_float}, b={b_float}, HW={hw_val}, REF={ref_val}, diff={diff}"
                            )

                        pbar.update(1)

    dut._log.info(f"FPU test completed: {mismatch_count} mismatches out of {total_tests} operations.")
    dut._log.info(f"Test passed: {mismatch_count/total_tests*100:.2f}%")
    assert mismatch_count == 0, f"Found {mismatch_count} mismatches in {total_tests} tests."