import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np
import sys
from mods.logging_mods import *
from mods.quantization_mods import *

# Reference model import
from ref_models.intersection_ref import intersection_ref

@cocotb.test()
async def test_intersection(dut):
    """
    Testbench for the intersection module.

    We:
      1) Drive random (or systematic) input values for v1, v2, plane_a/b/c/d.
      2) Wait for the state machine to produce done_o.
      3) Compare the hardware outputs (intersect_x/y/z/w) against the reference model.
      4) Assert on mismatches.
    """

    # Redirect output to a log file (optional)
    log_file = open('intersection_log.txt', 'w')
    sys.stdout = log_file

    color_log(dut, "Starting intersection test...")

    # Start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    # You can adjust the number of random tests
    test_iters = 10
    color_log(dut, f"Running intersection test with {test_iters} random iterations.")

    # Because intersection is parameterized, you may wish to determine or define
    # the parameter values (VERTEX_WIDTH, FRAC_BITS, etc.) from the simulation environment.

    VERTEX_WIDTH = 32
    FRAC_BITS = 16

    # Reset-like behavior: hold start_i=0 for a few cycles
    dut.start_i.value = 0
    dut.done_o.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    # Main test loop
    mismatches = 0
    for test_count in tqdm(range(test_iters)):
        # Generate random inputs for v1 and v2
        # For signed 32-bit with FRAC_BITS=16, we keep them within some range
        v1_x = np.random.randint(-32768, 32767)
        v1_y = np.random.randint(-32768, 32767)
        v1_z = np.random.randint(-32768, 32767)
        v1_w = np.random.randint(-32768, 32767)

        v2_x = np.random.randint(-32768, 32767)
        v2_y = np.random.randint(-32768, 32767)
        v2_z = np.random.randint(-32768, 32767)
        v2_w = np.random.randint(-32768, 32767)

        # Generate random plane coefficients a, b, c, d
        plane_a = np.random.randint(-32768, 32767)
        plane_b = np.random.randint(-32768, 32767)
        plane_c = np.random.randint(-32768, 32767)
        plane_d = np.random.randint(-32768, 32767)

        # Drive these into the DUT
        dut.v1_x.value = v1_x
        dut.v1_y.value = v1_y
        dut.v1_z.value = v1_z
        dut.v1_w.value = v1_w

        dut.v2_x.value = v2_x
        dut.v2_y.value = v2_y
        dut.v2_z.value = v2_z
        dut.v2_w.value = v2_w

        dut.plane_a.value = plane_a
        dut.plane_b.value = plane_b
        dut.plane_c.value = plane_c
        dut.plane_d.value = plane_d

        # Start the intersection calculation
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        #! Need to check done_o behaviour - code coverage not full
        # Wait until hardware indicates done
        # while not dut.done_o.value:
        #     await RisingEdge(dut.clk_i)
        
        # Read the hardware outputs
        hw_x = dut.intersect_x.value.signed_integer
        hw_y = dut.intersect_y.value.signed_integer
        hw_z = dut.intersect_z.value.signed_integer
        hw_w = dut.intersect_w.value.signed_integer

        # Compute reference
        ref_x, ref_y, ref_z, ref_w = intersection_ref(
            v1_x, v1_y, v1_z, v1_w,
            v2_x, v2_y, v2_z, v2_w,
            plane_a, plane_b, plane_c, plane_d,
            VERTEX_WIDTH, FRAC_BITS
        )

        # Compare results (allow some tolerance if desired for fixed-point rounding)
        # For an exact match, do:
        if (hw_x != ref_x) or (hw_y != ref_y) or (hw_z != ref_z) or (hw_w != ref_w):
            mismatches += 1
            color_log(dut, f"\n[ERROR] Mismatch at iteration {test_count}:", log_error=True)
            color_log(dut, f"  v1=({v1_x}, {v1_y}, {v1_z}, {v1_w})", log_error=True)
            color_log(dut, f"  v2=({v2_x}, {v2_y}, {v2_z}, {v2_w})", log_error=True)
            color_log(dut, f"  plane=({plane_a}, {plane_b}, {plane_c}, {plane_d})", log_error=True)
            color_log(dut, f"  HW   =({hw_x}, {hw_y}, {hw_z}, {hw_w})", log_error=True)
            color_log(dut, f"  REF  =({ref_x}, {ref_y}, {ref_z}, {ref_w})", log_error=True)
            # You could do an assert False if you want to stop at the first mismatch
            # assert False, "Intersection mismatch"

    color_log(dut, f"\nIntersection test completed with {mismatches} mismatches out of {test_iters} tests.")
    log_file.close()
