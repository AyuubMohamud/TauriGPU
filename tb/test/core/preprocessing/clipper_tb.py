import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np
from ref_model.clipper_ref import clip_triangle_float, compare_vertices, float_to_fixed_12_12, fixed_12_12_to_float

# @cocotb.test()
async def test_clipper(dut):
    """
    Test the clipper module with various triangle configurations,
    waiting properly for done_o and handling reset_n.
    """

    # 1) Create and start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    # 2) Assert reset for a few cycles before starting
    dut.reset_n.value = 0
    dut.start_i.value = 0  # make sure start is low
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    # 3) De-assert reset
    dut.reset_n.value = 1
    await RisingEdge(dut.clk_i)

    # Constants
    MIN_VAL = -1280.0
    MAX_VAL = +1279.0
    test_iters = 1000
    TOL = 10  # Tolerance for floating point comparisons
    
    print(f"\nRunning clipper tests with {test_iters} random triangle configurations...")

    rng = np.random.default_rng()
    mismatches = 0
    vertex_errors = []

    for test_count in tqdm(range(test_iters), desc="Testing Clipper"):
        # Generate random triangle
        v0_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v0_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v0_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v0_wf = 1.0

        v1_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_wf = 1.0

        v2_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_wf = 1.0

        # Generate random plane
        plane_normal_x = rng.uniform(-1.0, 1.0)
        plane_normal_y = rng.uniform(-1.0, 1.0)
        plane_normal_z = rng.uniform(-1.0, 1.0)
        plane_offset   = rng.uniform(-1.0, 1.0)

        # Normalize plane normal
        norm = np.sqrt(plane_normal_x**2 + plane_normal_y**2 + plane_normal_z**2)
        if norm < 1e-6:
            # Degenerate normal, skip
            continue

        plane_normal_x /= norm
        plane_normal_y /= norm
        plane_normal_z /= norm

        # Convert inputs to 12.12 fixed point
        dut.v0_x_i.value = float_to_fixed_12_12(v0_xf) & 0xFFFFFF
        dut.v0_y_i.value = float_to_fixed_12_12(v0_yf) & 0xFFFFFF
        dut.v0_z_i.value = float_to_fixed_12_12(v0_zf) & 0xFFFFFF
        dut.v0_w_i.value = float_to_fixed_12_12(v0_wf) & 0xFFFFFF

        dut.v1_x_i.value = float_to_fixed_12_12(v1_xf) & 0xFFFFFF
        dut.v1_y_i.value = float_to_fixed_12_12(v1_yf) & 0xFFFFFF
        dut.v1_z_i.value = float_to_fixed_12_12(v1_zf) & 0xFFFFFF
        dut.v1_w_i.value = float_to_fixed_12_12(v1_wf) & 0xFFFFFF

        dut.v2_x_i.value = float_to_fixed_12_12(v2_xf) & 0xFFFFFF
        dut.v2_y_i.value = float_to_fixed_12_12(v2_yf) & 0xFFFFFF
        dut.v2_z_i.value = float_to_fixed_12_12(v2_zf) & 0xFFFFFF
        dut.v2_w_i.value = float_to_fixed_12_12(v2_wf) & 0xFFFFFF

        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal_x) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal_y) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal_z) & 0xFFFFFF
        dut.plane_offset_i.value   = float_to_fixed_12_12(plane_offset)   & 0xFFFFFF

        # 4) Pulse start_i for at least one clock so FSM sees it
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # 5) Wait for done_o to go high
        #    This ensures the DUT has fully processed the input
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # 6) Now capture outputs and compare to reference
        ref_vertices, ref_num_triangles, ref_valid = clip_triangle_float(
            v0_xf, v0_yf, v0_zf, v0_wf,
            v1_xf, v1_yf, v1_zf, v1_wf,
            v2_xf, v2_yf, v2_zf, v2_wf,
            plane_normal_x, plane_normal_y, plane_normal_z, plane_offset
        )

        hw_valid = bool(dut.valid_o.value)
        hw_num_triangles = int(dut.num_triangles_o.value)

        # Check valid & num_triangles
        if (hw_valid != ref_valid) or (hw_num_triangles != ref_num_triangles):
            mismatches += 1
            print(f"\n[ERROR] Output flags mismatch @ iteration {test_count}")
            print(f"  HW:  valid={hw_valid}, num_triangles={hw_num_triangles}")
            print(f"  REF: valid={ref_valid}, num_triangles={ref_num_triangles}")
            continue

        # If invalid, skip vertex checks
        if not ref_valid:
            continue

        # Collect hardware vertices
        hw_vertices = []

        # First triangle outputs
        hw_vertices.extend([
            (fixed_12_12_to_float(dut.clipped_v0_x_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v0_y_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v0_z_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v0_w_o.value.signed_integer)),

            (fixed_12_12_to_float(dut.clipped_v1_x_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v1_y_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v1_z_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v1_w_o.value.signed_integer)),

            (fixed_12_12_to_float(dut.clipped_v2_x_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v2_y_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v2_z_o.value.signed_integer),
             fixed_12_12_to_float(dut.clipped_v2_w_o.value.signed_integer))
        ])

        # If hardware says there are 2 triangles, read the second set
        if hw_num_triangles == 2:
            hw_vertices.extend([
                (fixed_12_12_to_float(dut.clipped_v3_x_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v3_y_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v3_z_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v3_w_o.value.signed_integer)),

                (fixed_12_12_to_float(dut.clipped_v4_x_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v4_y_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v4_z_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v4_w_o.value.signed_integer)),

                (fixed_12_12_to_float(dut.clipped_v5_x_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v5_y_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v5_z_o.value.signed_integer),
                 fixed_12_12_to_float(dut.clipped_v5_w_o.value.signed_integer))
            ])

        # Compare hardware vs. reference
        if len(hw_vertices) != len(ref_vertices):
            mismatches += 1
            print(f"\n[ERROR] Vertex count mismatch @ iteration {test_count}")
            print(f"  HW has {len(hw_vertices)} vertices, REF has {len(ref_vertices)}")
        else:
            for i, (hw_v, ref_v) in enumerate(zip(hw_vertices, ref_vertices)):
                if not compare_vertices(hw_v, ref_v, TOL):
                    mismatches += 1
                    vertex_errors.append(test_count)
                    print(f"\n[ERROR] Vertex {i} mismatch @ iteration {test_count}")
                    print(f"  HW  = {hw_v}")
                    print(f"  REF = {ref_v}")

    print(f"\nTest completed: {mismatches} mismatch(es) in {test_iters} iterations.")
    assert mismatches == 0, f"{mismatches} mismatch(es) found."

# @cocotb.test()
async def test_clipper_classification_only(dut):
    """
    Test just the classification correctness in the clipper module.
    We use carefully chosen inputs that should yield 0,1,2,3 vertices inside.
    """

    # 1) Create and start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    # 2) Assert reset for a few cycles before starting
    dut.reset_n.value = 0
    dut.start_i.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    # 3) De-assert reset
    dut.reset_n.value = 1
    await RisingEdge(dut.clk_i)

    # We'll define some "test vectors" that produce known inside_count results.
    # Each entry = (v0, v1, v2, plane, expected_valid, expected_num_triangles)
    # plane = (plane_normal_x, plane_normal_y, plane_normal_z, plane_offset)
    #
    # Because we only want to see classification:
    # - 0 inside -> we expect "valid=0, num_tris=0"
    # - 1 inside -> "valid=1, num_tris=1"
    # - 2 inside -> "valid=1, num_tris=2"
    # - 3 inside -> "valid=1, num_tris=1"
    #
    # We'll pick an easy plane: x=0 (plane_normal=(1,0,0), offset=0)
    # Then we put vertices at negative or positive x to control inside vs outside.

    test_vectors = [
        # 0 inside: all x < 0
        ((-10, 0, 0, 1), (-20, 5, 0, 1), (-30, -5, 0, 1),  # all negative x
         (1, 0, 0, 0),  # plane x=0
         False, 0),

        # 1 inside: v0_x>0, others <0
        ((+10, 0, 0, 1), (-20, 5, 0, 1), (-30, -5, 0, 1),
         (1, 0, 0, 0),
         True, 1),

        # 2 inside: v0_x>0, v1_x>0, v2_x<0
        ((+10, 0, 0, 1), (+20, 5, 0, 1), (-30, -5, 0, 1),
         (1, 0, 0, 0),
         True, 2),

        # 3 inside: all x>0
        ((+10, 0, 0, 1), (+20, 5, 0, 1), (+30, -5, 0, 1),
         (1, 0, 0, 0),
         True, 1),
    ]

    # Now run each test vector:
    mismatches = 0
    for idx, (v0, v1, v2, plane, exp_valid, exp_tris) in enumerate(test_vectors):

        # 4) Convert each to fixed 12.12
        # v0, v1, v2 are (x,y,z,w)
        v0x_fix = float_to_fixed_12_12(v0[0]) & 0xFFFFFF
        v0y_fix = float_to_fixed_12_12(v0[1]) & 0xFFFFFF
        v0z_fix = float_to_fixed_12_12(v0[2]) & 0xFFFFFF
        v0w_fix = float_to_fixed_12_12(v0[3]) & 0xFFFFFF

        v1x_fix = float_to_fixed_12_12(v1[0]) & 0xFFFFFF
        v1y_fix = float_to_fixed_12_12(v1[1]) & 0xFFFFFF
        v1z_fix = float_to_fixed_12_12(v1[2]) & 0xFFFFFF
        v1w_fix = float_to_fixed_12_12(v1[3]) & 0xFFFFFF

        v2x_fix = float_to_fixed_12_12(v2[0]) & 0xFFFFFF
        v2y_fix = float_to_fixed_12_12(v2[1]) & 0xFFFFFF
        v2z_fix = float_to_fixed_12_12(v2[2]) & 0xFFFFFF
        v2w_fix = float_to_fixed_12_12(v2[3]) & 0xFFFFFF

        plane_x_fix = float_to_fixed_12_12(plane[0]) & 0xFFFFFF
        plane_y_fix = float_to_fixed_12_12(plane[1]) & 0xFFFFFF
        plane_z_fix = float_to_fixed_12_12(plane[2]) & 0xFFFFFF
        plane_d_fix = float_to_fixed_12_12(plane[3]) & 0xFFFFFF

        # 5) Drive DUT inputs
        dut.v0_x_i.value = v0x_fix
        dut.v0_y_i.value = v0y_fix
        dut.v0_z_i.value = v0z_fix
        dut.v0_w_i.value = v0w_fix

        dut.v1_x_i.value = v1x_fix
        dut.v1_y_i.value = v1y_fix
        dut.v1_z_i.value = v1z_fix
        dut.v1_w_i.value = v1w_fix

        dut.v2_x_i.value = v2x_fix
        dut.v2_y_i.value = v2y_fix
        dut.v2_z_i.value = v2z_fix
        dut.v2_w_i.value = v2w_fix

        dut.plane_normal_x_i.value = plane_x_fix
        dut.plane_normal_y_i.value = plane_y_fix
        dut.plane_normal_z_i.value = plane_z_fix
        dut.plane_offset_i.value   = plane_d_fix

        # 6) Start the DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # 7) Wait for done signal
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # 8) Check the HW outputs
        hw_valid   = bool(dut.valid_o.value)
        hw_tris    = int(dut.num_triangles_o.value)

        # 9) Compare to expected
        if (hw_valid != exp_valid) or (hw_tris != exp_tris):
            mismatches += 1
            print(f"[CLASSIFY ERROR] idx={idx}: Expected valid={exp_valid}, num_tris={exp_tris}  "
                  f"but got valid={hw_valid}, num_tris={hw_tris}.")

    # Final check
    if mismatches == 0:
        print(f"[OK] Classification test passed all {len(test_vectors)} checks.")
    else:
        print(f"[FAIL] Classification test found {mismatches} mismatch(es).")
    assert mismatches == 0, f"{mismatches} classification mismatch(es) found."

@cocotb.test()
async def test_clipper_dot_product_direct(dut):
    """Test dot product calculation with a single known case."""

    # Create and start clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    # Reset
    dut.reset_n.value = 0
    dut.start_i.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)
    dut.reset_n.value = 1
    await RisingEdge(dut.clk_i)

    # Test case: Simple values that multiply cleanly
    v0 = [100.0, 50.0, -50.0, 100.0]  # x, y, z, w
    plane = [50.0, 100.0, 50.0, -25.0]  # normal_x, normal_y, normal_z, offset

    # Expected result calculated by hand:
    # 100.0 * 50.0 + 50.0 * 100.0 + (-50.0) * 50.0 + 100.0 * (-25.0)
    # = 5000.0 + 5000.0 - 2500.0 - 2500.0
    # = 5000.0
    expected_dot_v0 = 5000.0

    # Convert to fixed point
    dut.v0_x_i.value = float_to_fixed_12_12(v0[0]) & 0xFFFFFF
    dut.v0_y_i.value = float_to_fixed_12_12(v0[1]) & 0xFFFFFF
    dut.v0_z_i.value = float_to_fixed_12_12(v0[2]) & 0xFFFFFF
    dut.v0_w_i.value = float_to_fixed_12_12(v0[3]) & 0xFFFFFF

    dut.plane_normal_x_i.value = float_to_fixed_12_12(plane[0]) & 0xFFFFFF
    dut.plane_normal_y_i.value = float_to_fixed_12_12(plane[1]) & 0xFFFFFF
    dut.plane_normal_z_i.value = float_to_fixed_12_12(plane[2]) & 0xFFFFFF
    dut.plane_offset_i.value = float_to_fixed_12_12(plane[3]) & 0xFFFFFF

    # Start the DUT
    dut.start_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.start_i.value = 0

    # Wait one more cycle for dot product to compute
    while dut.curr_state.value != 2:
        await RisingEdge(dut.clk_i)

    # Get actual result and convert back to float
    actual_dot_v0 = fixed_12_12_to_float(dut.dot_product_v0.value.signed_integer)

    print(f"\nDot Product Test Results:")
    print(f"Expected: {expected_dot_v0:.6f}")
    print(f"Actual:   {actual_dot_v0:.6f}")

    assert abs(actual_dot_v0 - expected_dot_v0) < 1e-6, "Dot product mismatch."
    

