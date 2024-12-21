import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import numpy as np
import sys

from ref_models.intersection_ref import compute_intersection

@cocotb.test()
async def test_intersection_module(dut):
    """Constrained Random Testing for the Intersection Module"""

    # Initialize the clock
    clock = Clock(dut.clk_i, 10, units='ns')  # 100 MHz
    cocotb.start_soon(clock.start())

    # Reset logic if necessary
    dut.reset_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.reset_i.value = 0
    await RisingEdge(dut.clk_i)

    # Define the number of test iterations
    test_iters = 1000

    # Define the width parameters
    VERTEX_WIDTH = int(dut.VERTEX_WIDTH.value)
    FRAC_BITS = 16  # As per the intersection module parameter
    NEWTON_ITERATIONS = 3  # As per the intersection module parameter

    # Function to generate random fixed-point numbers
    def rand_fixed(width):
        return np.random.randint(-(2**(width-1)), 2**(width-1))

    # Start the test
    for test_count in range(test_iters):
        # Generate random vertices and plane coefficients
        v1_x = rand_fixed(VERTEX_WIDTH)
        v1_y = rand_fixed(VERTEX_WIDTH)
        v1_z = rand_fixed(VERTEX_WIDTH)
        v1_w = rand_fixed(VERTEX_WIDTH)

        v2_x = rand_fixed(VERTEX_WIDTH)
        v2_y = rand_fixed(VERTEX_WIDTH)
        v2_z = rand_fixed(VERTEX_WIDTH)
        v2_w = rand_fixed(VERTEX_WIDTH)

        plane_a = rand_fixed(VERTEX_WIDTH)
        plane_b = rand_fixed(VERTEX_WIDTH)
        plane_c = rand_fixed(VERTEX_WIDTH)
        plane_d = rand_fixed(VERTEX_WIDTH)

        # Convert fixed-point to floating-point for the reference model
        # Assuming the inputs are in Q16.16 format
        def fixed_to_float(val):
            return val / (1 << FRAC_BITS)

        v1 = (
            fixed_to_float(v1_x),
            fixed_to_float(v1_y),
            fixed_to_float(v1_z),
            fixed_to_float(v1_w)
        )

        v2 = (
            fixed_to_float(v2_x),
            fixed_to_float(v2_y),
            fixed_to_float(v2_z),
            fixed_to_float(v2_w)
        )

        plane = (
            fixed_to_float(plane_a),
            fixed_to_float(plane_b),
            fixed_to_float(plane_c),
            fixed_to_float(plane_d)
        )

        # Compute expected intersection using the reference model
        intersect_expected, valid_expected = compute_intersection(v1, v2, plane)

        # Apply inputs to DUT
        dut.v1_x.value = v1_x
        dut.v1_y.value = v1_y
        dut.v1_z.value = v1_z
        dut.v1_w.value = v1_w

        dut.v2_x.value = v2_x
        dut.v2_y.value = v2_y
        dut.v2_z.value = v2_z
        dut.v2_w.value = v2_w

        dut.plane_a_i.value = plane_a
        dut.plane_b_i.value = plane_b
        dut.plane_c_i.value = plane_c
        dut.plane_d_i.value = plane_d

        # Start the intersection calculation
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for the DUT to signal done
        while dut.done_o.value == 0:
            await RisingEdge(dut.clk_i)

        # Read DUT outputs
        intersect_x_dut = int(dut.intersect_x.value)
        intersect_y_dut = int(dut.intersect_y.value)
        intersect_z_dut = int(dut.intersect_z.value)
        intersect_w_dut = int(dut.intersect_w.value)

        # Convert DUT outputs from fixed-point to floating-point
        intersect_dut = (
            intersect_x_dut / (1 << FRAC_BITS),
            intersect_y_dut / (1 << FRAC_BITS),
            intersect_z_dut / (1 << FRAC_BITS),
            intersect_w_dut / (1 << FRAC_BITS)
        )

        # Determine DUT's validity output
        dut_valid = bool(dut.valid_o.value)

        # Compare the validity flags
        if dut_valid != valid_expected:
            dut._log.error(f"Test {test_count}: Validity mismatch. DUT: {dut_valid}, Expected: {valid_expected}")
            dut._log.error(f"v1: {v1}, v2: {v2}, plane: {plane}")
            assert False, f"Validity mismatch at test {test_count}"

        # If intersection is valid, compare the intersection points
        if valid_expected:
            # Allow a small tolerance due to fixed-point precision
            tolerance = 1e-3  # Adjust as necessary

            for i, (dut_val, exp_val) in enumerate(zip(intersect_dut, intersect_expected)):
                if not np.isclose(dut_val, exp_val, atol=tolerance):
                    dut._log.error(f"Test {test_count}: Intersection mismatch at coordinate {i}. DUT: {dut_val}, Expected: {exp_val}")
                    dut._log.error(f"v1: {v1}, v2: {v2}, plane: {plane}")
                    assert False, f"Intersection mismatch at test {test_count}, coordinate {i}"

        # Optional: Add a progress indicator
        if (test_count + 1) % 100 == 0:
            dut._log.info(f"Completed {test_count + 1}/{test_iters} tests.")

    # Final assertion
    dut._log.info(f"All {test_iters} intersection tests passed successfully.")
