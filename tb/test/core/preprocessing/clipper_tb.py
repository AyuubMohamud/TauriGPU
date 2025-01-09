import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np
from ref_model.clipper_ref import clip_triangle_float, compare_vertices, float_to_fixed_12_12, fixed_12_12_to_float

@cocotb.test()
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
    vertex_count_mismatches = 0
    num_tri_mismatches = 0

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
            num_tri_mismatches += 1
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
            vertex_count_mismatches += 1
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
    print(f"  Vertex count mismatches: {vertex_count_mismatches}")
    print(f"  Vertex mismatches: {len(vertex_errors)}")
    print(f"  Num_Triangle mismatches: {num_tri_mismatches}")
    assert mismatches == 0, f"{mismatches} mismatch(es) found."

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
    
@cocotb.test()
async def test_clipper_dot_product_random(dut):
    """Test dot product calculation with multiple random test cases."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0  # Keep values reasonable for 12.12 fixed point
    rng = np.random.default_rng()
    TOL = 0.1  # Tolerance for floating point comparisons
    
    mismatches = 0
    print(f"\nRunning {NUM_TESTS} random dot product tests...")

    for test_idx in tqdm(range(NUM_TESTS)):
        # Generate random values with controlled magnitudes
        v0 = [
            rng.uniform(-MAX_VAL, MAX_VAL),  # x
            rng.uniform(-MAX_VAL, MAX_VAL),  # y
            rng.uniform(-MAX_VAL, MAX_VAL),  # z
            rng.uniform(-MAX_VAL, MAX_VAL)   # w
        ]
        
        # Generate random plane with normalized normal vector
        plane_normal = [
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0)
        ]
        
        # Normalize the normal vector
        norm = np.sqrt(sum(x*x for x in plane_normal))
        plane_normal = [x/norm for x in plane_normal]
        
        # Add random offset
        plane = plane_normal + [rng.uniform(-1.0, 1.0)]  # [nx, ny, nz, offset]

        # Calculate expected result
        expected_dot = sum(v * p for v, p in zip(v0, plane))

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

        # Wait until we're in CLASSIFY state
        while dut.curr_state.value != 1:  # Assuming CLASSIFY is state 1
            await RisingEdge(dut.clk_i)
            
        # Wait one more cycle for dot product to compute
        await RisingEdge(dut.clk_i)

        # Get actual result and convert back to float
        actual_dot = fixed_12_12_to_float(dut.dot_product_v0.value.signed_integer)

        # Compare with tolerance
        if abs(actual_dot - expected_dot) > TOL:
            mismatches += 1
            print(f"\n[ERROR] Dot product mismatch @ test {test_idx}")
            print(f"Vertex:  ({v0[0]:.3f}, {v0[1]:.3f}, {v0[2]:.3f}, {v0[3]:.3f})")
            print(f"Plane:   ({plane[0]:.3f}, {plane[1]:.3f}, {plane[2]:.3f}, {plane[3]:.3f})")
            print(f"Expected: {expected_dot:.6f}")
            print(f"Actual:   {actual_dot:.6f}")
            print(f"Diff:     {abs(actual_dot - expected_dot):.6f}")

        # Wait until we're back in IDLE before next test
        while dut.curr_state.value != 0:  # Assuming IDLE is state 0
            await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} dot product mismatch(es) found."

@cocotb.test()
async def test_clipper_vertex_count_random(dut):
    """Test vertex_inside_count calculation with random test cases."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    mismatches = 0

    print(f"\nRunning {NUM_TESTS} random vertex count tests...")

    for test_idx in tqdm(range(NUM_TESTS)):
        # Generate random vertex positions
        vertices = []
        for _ in range(3):  # For v0, v1, v2
            vertices.append([
                rng.uniform(-MAX_VAL, MAX_VAL),  # x
                rng.uniform(-MAX_VAL, MAX_VAL),  # y
                rng.uniform(-MAX_VAL, MAX_VAL),  # z
                1.0                              # w
            ])

        # Generate random plane with normalized normal vector
        plane_normal = [
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0)
        ]
        
        # Normalize the normal vector
        norm = np.sqrt(sum(x*x for x in plane_normal))
        plane_normal = [x/norm for x in plane_normal]
        plane_offset = rng.uniform(-1.0, 1.0)

        # Calculate expected vertex count
        exp_inside_count = 0
        vertex_status = []
        for vertex in vertices:
            # Compute dot product
            dot_product = sum(v * n for v, n in zip(vertex[:3], plane_normal))
            dot_product += vertex[3] * plane_offset
            vertex_status.append(dot_product >= 0)
            if dot_product >= 0:
                exp_inside_count += 1

        # Convert to fixed point and drive inputs
        # V0
        dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
        dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
        dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
        dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

        # V1
        dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
        dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
        dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
        dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

        # V2
        dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
        dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
        dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
        dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

        # Plane
        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
        dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

        # Start the DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait until classification is done
        while dut.curr_state.value != 2:  # Wait until we leave CLASSIFY state
            await RisingEdge(dut.clk_i)

        # Get the actual vertex count
        actual_count = int(dut.vertex_inside_count.value)
        actual_inside = [bool(dut.vertex_inside.value & (1 << i)) for i in range(3)]

        # Compare results
        if actual_count != exp_inside_count or actual_inside != vertex_status:
            mismatches += 1
            print(f"\n[ERROR] Vertex count mismatch @ test {test_idx}")
            print(f"Expected count: {exp_inside_count}, Actual count: {actual_count}")
            print("Vertex status (inside/outside):")
            print(f"Expected: {vertex_status}")
            print(f"Actual:   {actual_inside}")
            print("\nInputs that caused this error:")
            for i, v in enumerate(vertices):
                print(f"V{i}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
            print(f"Plane: normal=({plane_normal[0]:.3f}, {plane_normal[1]:.3f}, {plane_normal[2]:.3f}), offset={plane_offset:.3f}")

        # Wait until we're back in IDLE before next test
        while dut.curr_state.value != 0:
            await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} vertex count mismatch(es) found."

@cocotb.test()
async def test_clipper_num_triangles(dut):
    """Test num_triangles_o output with controlled test cases and random tests."""

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

    # Known test vectors for specific cases
    # Format: (v0, v1, v2, plane, expected_valid, expected_num_triangles)
    # Each vertex is (x,y,z,w)
    # Plane is (normal_x, normal_y, normal_z, offset)
    test_vectors = [
        # Case 0: All vertices outside (0 triangles)
        ((-10, 0, 0, 1), (-20, 0, 0, 1), (-30, 0, 0, 1),
         (1, 0, 0, 0),  # plane x=0
         False, 0),

        # Case 1: One vertex inside (1 triangle)
        ((10, 0, 0, 1), (-20, 0, 0, 1), (-30, 0, 0, 1),
         (1, 0, 0, 0),
         True, 1),

        # Case 2: Two vertices inside (2 triangles - quad split)
        ((10, 0, 0, 1), (20, 0, 0, 1), (-30, 0, 0, 1),
         (1, 0, 0, 0),
         True, 2),

        # Case 3: All vertices inside (1 triangle - no clipping)
        ((10, 0, 0, 1), (20, 0, 0, 1), (30, 0, 0, 1),
         (1, 0, 0, 0),
         True, 1),
    ]

    print("\nTesting specific vertex configurations...")
    mismatches = 0

    # Test known configurations
    for idx, (v0, v1, v2, plane, exp_valid, exp_tris) in enumerate(test_vectors):
        # Convert to fixed point
        dut.v0_x_i.value = float_to_fixed_12_12(v0[0]) & 0xFFFFFF
        dut.v0_y_i.value = float_to_fixed_12_12(v0[1]) & 0xFFFFFF
        dut.v0_z_i.value = float_to_fixed_12_12(v0[2]) & 0xFFFFFF
        dut.v0_w_i.value = float_to_fixed_12_12(v0[3]) & 0xFFFFFF

        dut.v1_x_i.value = float_to_fixed_12_12(v1[0]) & 0xFFFFFF
        dut.v1_y_i.value = float_to_fixed_12_12(v1[1]) & 0xFFFFFF
        dut.v1_z_i.value = float_to_fixed_12_12(v1[2]) & 0xFFFFFF
        dut.v1_w_i.value = float_to_fixed_12_12(v1[3]) & 0xFFFFFF

        dut.v2_x_i.value = float_to_fixed_12_12(v2[0]) & 0xFFFFFF
        dut.v2_y_i.value = float_to_fixed_12_12(v2[1]) & 0xFFFFFF
        dut.v2_z_i.value = float_to_fixed_12_12(v2[2]) & 0xFFFFFF
        dut.v2_w_i.value = float_to_fixed_12_12(v2[3]) & 0xFFFFFF

        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane[0]) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane[1]) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane[2]) & 0xFFFFFF
        dut.plane_offset_i.value = float_to_fixed_12_12(plane[3]) & 0xFFFFFF

        # Start DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # Check results
        hw_valid = bool(dut.valid_o.value)
        hw_tris = int(dut.num_triangles_o.value)

        if (hw_valid != exp_valid) or (hw_tris != exp_tris):
            mismatches += 1
            print(f"\n[ERROR] Test vector {idx} mismatch:")
            print(f"Expected: valid={exp_valid}, num_triangles={exp_tris}")
            print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
            print("\nTest inputs:")
            print(f"V0: ({v0[0]}, {v0[1]}, {v0[2]}, {v0[3]})")
            print(f"V1: ({v1[0]}, {v1[1]}, {v1[2]}, {v1[3]})")
            print(f"V2: ({v2[0]}, {v2[1]}, {v2[2]}, {v2[3]})")
            print(f"Plane: normal=({plane[0]}, {plane[1]}, {plane[2]}), offset={plane[3]}")

    # Now do random tests
    NUM_RANDOM_TESTS = 1000
    print(f"\nRunning {NUM_RANDOM_TESTS} random configurations...")
    
    rng = np.random.default_rng()
    MAX_VAL = 100.0

    for test_idx in tqdm(range(NUM_RANDOM_TESTS)):
        # Generate random vertex positions
        vertices = []
        for _ in range(3):
            vertices.append([
                rng.uniform(-MAX_VAL, MAX_VAL),
                rng.uniform(-MAX_VAL, MAX_VAL),
                rng.uniform(-MAX_VAL, MAX_VAL),
                1.0
            ])

        # Generate and normalize plane normal
        plane_normal = [
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0),
            rng.uniform(-1.0, 1.0)
        ]
        norm = np.sqrt(sum(x*x for x in plane_normal))
        plane_normal = [x/norm for x in plane_normal]
        plane_offset = rng.uniform(-1.0, 1.0)

        # Calculate expected results
        vertex_dots = []
        inside_count = 0
        for v in vertices:
            dot = sum(v[i] * plane_normal[i] for i in range(3)) + v[3] * plane_offset
            vertex_dots.append(dot)
            if dot >= 0:
                inside_count += 1

        # Determine expected results
        exp_valid = inside_count > 0
        if inside_count == 0:
            exp_tris = 0
        elif inside_count == 2:
            exp_tris = 2
        else:
            exp_tris = 1

        # Drive inputs
        for i, v in enumerate(vertices):
            for j, comp in enumerate(['x', 'y', 'z', 'w']):
                setattr(dut, f'v{i}_{comp}_i', float_to_fixed_12_12(v[j]) & 0xFFFFFF)

        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
        dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

        # Start DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # Check results
        hw_valid = bool(dut.valid_o.value)
        hw_tris = int(dut.num_triangles_o.value)

        if (hw_valid != exp_valid) or (hw_tris != exp_tris):
            mismatches += 1
            print(f"\n[ERROR] Random test {test_idx} mismatch:")
            print(f"Expected: valid={exp_valid}, num_triangles={exp_tris}")
            print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
            print(f"Inside count: {inside_count}")
            print("\nTest inputs:")
            for i, v in enumerate(vertices):
                print(f"V{i}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
            print(f"Plane: normal=({plane_normal[0]:.3f}, {plane_normal[1]:.3f}, {plane_normal[2]:.3f}), offset={plane_offset:.3f}")
            print("Dot products:", vertex_dots)

    print(f"\nTest completed: {mismatches} mismatch(es) in {len(test_vectors) + NUM_RANDOM_TESTS} total tests.")
    assert mismatches == 0, f"{mismatches} num_triangles mismatch(es) found."

@cocotb.test() # 2'd3
async def test_clipper_all_inside_case(dut):
    """Test clipping when all vertices are inside (no clipping needed)."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    TOL = 0.1
    mismatches = 0

    print(f"\nRunning {NUM_TESTS} all-inside vertex tests...")

    for test_idx in tqdm(range(NUM_TESTS)):
        # Generate random vertex positions
        # For the all-inside case, we'll put vertices on the positive side of the plane
        vertices = []
        for _ in range(3):
            vertices.append([
                rng.uniform(0.1, MAX_VAL),     # Keep x positive
                rng.uniform(-MAX_VAL, MAX_VAL), # y can be anything
                rng.uniform(-MAX_VAL, MAX_VAL), # z can be anything
                1.0                             # w is 1
            ])

        # Use simple plane x=0 to ensure all vertices are inside
        plane_normal = [1.0, 0.0, 0.0]  # Points along +x axis
        plane_offset = 0.0               # Plane at x=0

        # Drive inputs
        # V0
        dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
        dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
        dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
        dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

        # V1
        dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
        dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
        dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
        dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

        # V2
        dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
        dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
        dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
        dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

        # Plane
        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
        dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

        # Start DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # Check results
        hw_valid = bool(dut.valid_o.value)
        hw_tris = int(dut.num_triangles_o.value)

        # For all-inside case, we expect:
        assert hw_valid == True, f"Expected valid=True but got {hw_valid}"
        assert hw_tris == 1, f"Expected num_triangles=1 but got {hw_tris}"
        
        # Get hardware vertices
        hw_vertices = [
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
        ]

        # For all-inside case, output vertices should exactly match input vertices
        for i, (hw_v, ref_v) in enumerate(zip(hw_vertices, vertices)):
            if not compare_vertices(hw_v, ref_v, TOL):
                mismatches += 1
                print(f"\n[ERROR] Vertex {i} mismatch @ test {test_idx}")
                print(f"Input:  ({ref_v[0]:.3f}, {ref_v[1]:.3f}, {ref_v[2]:.3f}, {ref_v[3]:.3f})")
                print(f"Output: ({hw_v[0]:.3f}, {hw_v[1]:.3f}, {hw_v[2]:.3f}, {hw_v[3]:.3f})")
                print(f"Diff: ({abs(ref_v[0]-hw_v[0]):.3f}, {abs(ref_v[1]-hw_v[1]):.3f}, "
                      f"{abs(ref_v[2]-hw_v[2]):.3f}, {abs(ref_v[3]-hw_v[3]):.3f})")

        # Wait until we're back in IDLE before next test
        while dut.curr_state.value != 0:
            await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} vertex mismatch(es) found."

@cocotb.test() # 2'd0
async def test_clipper_all_outside_case(dut):
    """Test clipping when all vertices are outside (triangle should be culled)."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    mismatches = 0

    print(f"\nRunning {NUM_TESTS} all-outside vertex tests...")

    for test_idx in tqdm(range(NUM_TESTS)):
        # Generate random vertex positions
        # For the all-outside case, we'll put vertices on the negative side of the plane
        vertices = []
        for _ in range(3):
            vertices.append([
                rng.uniform(-MAX_VAL, -0.1),   # Keep x negative
                rng.uniform(-MAX_VAL, MAX_VAL), # y can be anything
                rng.uniform(-MAX_VAL, MAX_VAL), # z can be anything
                1.0                             # w is 1
            ])

        # Use simple plane x=0 to ensure all vertices are outside
        plane_normal = [1.0, 0.0, 0.0]  # Points along +x axis
        plane_offset = 0.0               # Plane at x=0

        # Drive inputs
        # V0
        dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
        dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
        dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
        dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

        # V1
        dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
        dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
        dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
        dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

        # V2
        dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
        dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
        dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
        dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

        # Plane
        dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
        dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
        dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
        dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

        # Start DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # Check results
        hw_valid = bool(dut.valid_o.value)
        hw_tris = int(dut.num_triangles_o.value)

        # For all-outside case, we expect:
        if hw_valid != False or hw_tris != 0:
            mismatches += 1
            print(f"\n[ERROR] Invalid output flags @ test {test_idx}")
            print(f"Expected: valid=False, num_triangles=0")
            print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
            print("\nTest inputs that caused error:")
            for i, v in enumerate(vertices):
                print(f"V{i}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
            print(f"Plane: normal=({plane_normal[0]}, {plane_normal[1]}, {plane_normal[2]}), offset={plane_offset}")
            print("\nVertex dot products with plane:")
            for i, v in enumerate(vertices):
                dot = v[0]*plane_normal[0] + v[1]*plane_normal[1] + v[2]*plane_normal[2] + v[3]*plane_offset
                print(f"V{i} dot product: {dot:.3f}")

            # Also print internal state
            print("\nInternal state:")
            print(f"vertex_inside: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
            print(f"vertex_inside_count: {int(dut.vertex_inside_count.value)}")

        # Wait until we're back in IDLE before next test
        while dut.curr_state.value != 0:
            await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} case(s) incorrectly handled."

    # Additional sanity check - Verify output remains stable
    # Run one more test and check outputs don't change
    while dut.curr_state.value != 0:  # Make sure we're in IDLE
        await RisingEdge(dut.clk_i)

    # Generate one more test case
    test_vertex = [-1.0, 0.0, 0.0, 1.0]  # Clearly outside x=0 plane
    
    # Drive inputs
    for comp in ['x', 'y', 'z', 'w']:
        setattr(dut, f'v0_{comp}_i', float_to_fixed_12_12(test_vertex[{'x':0, 'y':1, 'z':2, 'w':3}[comp]]) & 0xFFFFFF)
        setattr(dut, f'v1_{comp}_i', float_to_fixed_12_12(test_vertex[{'x':0, 'y':1, 'z':2, 'w':3}[comp]]) & 0xFFFFFF)
        setattr(dut, f'v2_{comp}_i', float_to_fixed_12_12(test_vertex[{'x':0, 'y':1, 'z':2, 'w':3}[comp]]) & 0xFFFFFF)
    
    dut.plane_normal_x_i.value = float_to_fixed_12_12(1.0) & 0xFFFFFF
    dut.plane_normal_y_i.value = 0
    dut.plane_normal_z_i.value = 0
    dut.plane_offset_i.value = 0

    # Start DUT
    dut.start_i.value = 1
    await RisingEdge(dut.clk_i)
    dut.start_i.value = 0

    # Wait for done
    while not dut.done_o.value:
        await RisingEdge(dut.clk_i)

    # Capture initial outputs
    initial_outputs = {
        'v0': (dut.clipped_v0_x_o.value, dut.clipped_v0_y_o.value, dut.clipped_v0_z_o.value, dut.clipped_v0_w_o.value),
        'v1': (dut.clipped_v1_x_o.value, dut.clipped_v1_y_o.value, dut.clipped_v1_z_o.value, dut.clipped_v1_w_o.value),
        'v2': (dut.clipped_v2_x_o.value, dut.clipped_v2_y_o.value, dut.clipped_v2_z_o.value, dut.clipped_v2_w_o.value)
    }

    # Wait several cycles and verify outputs remain stable
    for _ in range(10):
        await RisingEdge(dut.clk_i)
        current_outputs = {
            'v0': (dut.clipped_v0_x_o.value, dut.clipped_v0_y_o.value, dut.clipped_v0_z_o.value, dut.clipped_v0_w_o.value),
            'v1': (dut.clipped_v1_x_o.value, dut.clipped_v1_y_o.value, dut.clipped_v1_z_o.value, dut.clipped_v1_w_o.value),
            'v2': (dut.clipped_v2_x_o.value, dut.clipped_v2_y_o.value, dut.clipped_v2_z_o.value, dut.clipped_v2_w_o.value)
        }
        if current_outputs != initial_outputs:
            print("\n[ERROR] Outputs not stable after triangle culled!")
            print("Initial outputs:", initial_outputs)
            print("Changed to:", current_outputs)
            assert False, "Outputs not stable when triangle culled"

    """Test clipping when exactly one vertex is inside the plane."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    TOL = 0.1
    mismatches = 0

    print(f"\nRunning {NUM_TESTS} one-vertex-inside tests...")

    # Test each vertex being the inside one
    for inside_vertex in range(3):
        print(f"\nTesting with v{inside_vertex} inside...")
        
        for test_idx in tqdm(range(NUM_TESTS//3)):
            # Generate vertices - one inside, two outside
            vertices = []
            for i in range(3):
                if i == inside_vertex:
                    # This vertex should be inside (x > 0)
                    vertices.append([
                        rng.uniform(0.1, MAX_VAL),     # Positive x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])
                else:
                    # This vertex should be outside (x < 0)
                    vertices.append([
                        rng.uniform(-MAX_VAL, -0.1),   # Negative x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])

            # Simple plane x=0
            plane_normal = [1.0, 0.0, 0.0]  # Points along +x axis
            plane_offset = 0.0               # Plane at x=0

            # Drive inputs
            for i, v in enumerate(vertices):
                dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
                dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
                dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
                dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

                dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
                dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
                dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
                dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

                dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
                dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
                dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
                dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

            dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
            dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
            dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
            dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

            # Start DUT
            dut.start_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.start_i.value = 0

            # Wait for done
            while not dut.done_o.value:
                await RisingEdge(dut.clk_i)

            # Check results
            hw_valid = bool(dut.valid_o.value)
            hw_tris = int(dut.num_triangles_o.value)

            # For one-inside case, we expect:
            if not hw_valid or hw_tris != 1:
                mismatches += 1
                print(f"\n[ERROR] Invalid output flags @ test {test_idx}")
                print(f"Expected: valid=True, num_triangles=1")
                print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
                print(f"\nVertex inside bits: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
                print(f"Inside count: {int(dut.vertex_inside_count.value)}")
                continue

            # Get hardware output vertices
            hw_vertices = [
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
            ]

            # Generate reference result using the reference model
            ref_vertices, ref_num_triangles, ref_valid = clip_triangle_float(
                vertices[0][0], vertices[0][1], vertices[0][2], vertices[0][3],
                vertices[1][0], vertices[1][1], vertices[1][2], vertices[1][3],
                vertices[2][0], vertices[2][1], vertices[2][2], vertices[2][3],
                plane_normal[0], plane_normal[1], plane_normal[2], plane_offset
            )

            # Compare the results
            if len(hw_vertices) != len(ref_vertices):
                mismatches += 1
                print(f"\n[ERROR] Vertex count mismatch @ test {test_idx}")
                print(f"Expected {len(ref_vertices)} vertices, got {len(hw_vertices)}")
            else:
                for i, (hw_v, ref_v) in enumerate(zip(hw_vertices, ref_vertices)):
                    if not compare_vertices(hw_v, ref_v, TOL):
                        mismatches += 1
                        print(f"\n[ERROR] Vertex {i} mismatch @ test {test_idx}")
                        print(f"Reference: ({ref_v[0]:.3f}, {ref_v[1]:.3f}, {ref_v[2]:.3f}, {ref_v[3]:.3f})")
                        print(f"Hardware:  ({hw_v[0]:.3f}, {hw_v[1]:.3f}, {hw_v[2]:.3f}, {hw_v[3]:.3f})")
                        print("\nInput vertices:")
                        for j, v in enumerate(vertices):
                            print(f"V{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        print(f"Inside vertex: {inside_vertex}")
                        print(f"vertex_inside: {bin(dut.vertex_inside.value)[2:].zfill(3)}")

            # Wait until we're back in IDLE before next test
            while dut.curr_state.value != 0:
                await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} mismatch(es) found."

@cocotb.test() # 2'd1
async def test_clipper_one_inside_case(dut):
    """Test clipping when exactly one vertex is inside the plane."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    TOL = 0.1
    mismatches = 0

    print(f"\nRunning {NUM_TESTS} one-vertex-inside tests...")

    # Test each vertex being the inside one
    for inside_vertex in range(3):
        print(f"\nTesting with v{inside_vertex} inside...")
        
        for test_idx in tqdm(range(NUM_TESTS//3)):
            # Generate vertices - one inside, two outside
            vertices = []
            for i in range(3):
                if i == inside_vertex:
                    # This vertex should be inside (x > 0)
                    vertices.append([
                        rng.uniform(0.1, MAX_VAL),     # Positive x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])
                else:
                    # This vertex should be outside (x < 0)
                    vertices.append([
                        rng.uniform(-MAX_VAL, -0.1),   # Negative x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])

            # Simple plane x=0
            plane_normal = [1.0, 0.0, 0.0]  # Points along +x axis
            plane_offset = 0.0               # Plane at x=0

            # Drive inputs
            dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
            dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
            dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
            dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

            dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
            dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
            dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
            dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

            dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
            dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
            dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
            dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

            dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
            dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
            dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
            dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

            # Start DUT
            dut.start_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.start_i.value = 0

            # Wait for done
            while not dut.done_o.value:
                await RisingEdge(dut.clk_i)

            # Check results
            hw_valid = bool(dut.valid_o.value)
            hw_tris = int(dut.num_triangles_o.value)

            # For one-inside case, we expect:
            if not hw_valid or hw_tris != 1:
                mismatches += 1
                print("\n==============================================")
                print(f"[ERROR] Invalid output flags @ test {test_idx}")
                print(f"Expected: valid=True, num_triangles=1")
                print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
                print(f"Inside vertex: {inside_vertex}")
                print(f"Vertex inside bits: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
                print(f"Inside count: {int(dut.vertex_inside_count.value)}")
                print("==============================================\n")
                continue

            # Get hardware output vertices
            hw_vertices = [
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
            ]

            # Generate reference result
            ref_vertices, ref_num_triangles, ref_valid = clip_triangle_float(
                vertices[0][0], vertices[0][1], vertices[0][2], vertices[0][3],
                vertices[1][0], vertices[1][1], vertices[1][2], vertices[1][3],
                vertices[2][0], vertices[2][1], vertices[2][2], vertices[2][3],
                plane_normal[0], plane_normal[1], plane_normal[2], plane_offset
            )

            # Compare results
            if len(hw_vertices) != len(ref_vertices):
                mismatches += 1
                print("\n==============================================")
                print(f"[ERROR] Vertex count mismatch @ test {test_idx}")
                print(f"Expected {len(ref_vertices)} vertices, got {len(hw_vertices)}")
                print("==============================================\n")
            else:
                for i, (hw_v, ref_v) in enumerate(zip(hw_vertices, ref_vertices)):
                    if not compare_vertices(hw_v, ref_v, TOL):
                        mismatches += 1
                        print("\n==============================================")
                        print(f"[ERROR] Vertex {i} mismatch @ test {test_idx}")
                        
                        print("\nInput Triangle:")
                        print("---------------")
                        for j, v in enumerate(vertices):
                            print(f"V{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        
                        print("\nPlane Equation:")
                        print("--------------")
                        print(f"Normal: ({plane_normal[0]:.3f}, {plane_normal[1]:.3f}, {plane_normal[2]:.3f})")
                        print(f"Offset: {plane_offset:.3f}")
                        
                        print("\nVertex Classification:")
                        print("--------------------")
                        print(f"Inside vertex: {inside_vertex}")
                        print(f"vertex_inside bits: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
                        print(f"vertex_inside_count: {int(dut.vertex_inside_count.value)}")

                        print("\nMismatched Vertex:")
                        print("----------------")
                        print(f"Index: {i}")
                        print(f"Reference: ({ref_v[0]:.3f}, {ref_v[1]:.3f}, {ref_v[2]:.3f}, {ref_v[3]:.3f})")
                        print(f"Hardware:  ({hw_v[0]:.3f}, {hw_v[1]:.3f}, {hw_v[2]:.3f}, {hw_v[3]:.3f})")
                        print(f"Diff:     ({abs(ref_v[0]-hw_v[0]):.3f}, {abs(ref_v[1]-hw_v[1]):.3f}, "
                              f"{abs(ref_v[2]-hw_v[2]):.3f}, {abs(ref_v[3]-hw_v[3]):.3f})")

                        print("\nAll Output Vertices:")
                        print("-----------------")
                        for j, v in enumerate(hw_vertices):
                            print(f"Out{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        print("==============================================\n")
                        break  # Break after first mismatch for clarity

            # Wait until we're back in IDLE before next test
            while dut.curr_state.value != 0:
                await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} mismatch(es) found."

@cocotb.test() # 2'd2
async def test_clipper_two_inside_case(dut):
    """Test clipping when exactly two vertices are inside the plane (quad split case)."""

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

    # Test parameters
    NUM_TESTS = 1000
    MAX_VAL = 100.0
    rng = np.random.default_rng()
    TOL = 1
    mismatches = 0

    # Track possible two-inside configurations
    configs = [
        (True, True, False),  # v0,v1 inside, v2 outside
        (True, False, True),  # v0,v2 inside, v1 outside
        (False, True, True)   # v1,v2 inside, v0 outside
    ]

    print(f"\nRunning {NUM_TESTS} two-vertices-inside tests...")

    for config_idx, inside_config in enumerate(configs):
        print(f"\nTesting configuration {config_idx}: vertices {[i for i,x in enumerate(inside_config) if x]} inside")
        
        for test_idx in tqdm(range(NUM_TESTS//3)):
            # Generate vertices based on configuration
            vertices = []
            for is_inside in inside_config:
                if is_inside:
                    # This vertex should be inside (x > 0)
                    vertices.append([
                        rng.uniform(0.1, MAX_VAL),     # Positive x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])
                else:
                    # This vertex should be outside (x < 0)
                    vertices.append([
                        rng.uniform(-MAX_VAL, -0.1),   # Negative x
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        rng.uniform(-MAX_VAL, MAX_VAL),
                        1.0
                    ])

            # Simple plane x=0
            plane_normal = [1.0, 0.0, 0.0]  # Points along +x axis
            plane_offset = 0.0               # Plane at x=0

            # Drive inputs
            dut.v0_x_i.value = float_to_fixed_12_12(vertices[0][0]) & 0xFFFFFF
            dut.v0_y_i.value = float_to_fixed_12_12(vertices[0][1]) & 0xFFFFFF
            dut.v0_z_i.value = float_to_fixed_12_12(vertices[0][2]) & 0xFFFFFF
            dut.v0_w_i.value = float_to_fixed_12_12(vertices[0][3]) & 0xFFFFFF

            dut.v1_x_i.value = float_to_fixed_12_12(vertices[1][0]) & 0xFFFFFF
            dut.v1_y_i.value = float_to_fixed_12_12(vertices[1][1]) & 0xFFFFFF
            dut.v1_z_i.value = float_to_fixed_12_12(vertices[1][2]) & 0xFFFFFF
            dut.v1_w_i.value = float_to_fixed_12_12(vertices[1][3]) & 0xFFFFFF

            dut.v2_x_i.value = float_to_fixed_12_12(vertices[2][0]) & 0xFFFFFF
            dut.v2_y_i.value = float_to_fixed_12_12(vertices[2][1]) & 0xFFFFFF
            dut.v2_z_i.value = float_to_fixed_12_12(vertices[2][2]) & 0xFFFFFF
            dut.v2_w_i.value = float_to_fixed_12_12(vertices[2][3]) & 0xFFFFFF

            dut.plane_normal_x_i.value = float_to_fixed_12_12(plane_normal[0]) & 0xFFFFFF
            dut.plane_normal_y_i.value = float_to_fixed_12_12(plane_normal[1]) & 0xFFFFFF
            dut.plane_normal_z_i.value = float_to_fixed_12_12(plane_normal[2]) & 0xFFFFFF
            dut.plane_offset_i.value = float_to_fixed_12_12(plane_offset) & 0xFFFFFF

            # Start DUT
            dut.start_i.value = 1
            await RisingEdge(dut.clk_i)
            dut.start_i.value = 0

            # Wait for done
            while not dut.done_o.value:
                await RisingEdge(dut.clk_i)

            # Check results
            hw_valid = bool(dut.valid_o.value)
            hw_tris = int(dut.num_triangles_o.value)

            # For two-inside case, we expect:
            if not hw_valid or hw_tris != 2:
                mismatches += 1
                print(f"\n[ERROR] Invalid output flags @ test {test_idx}")
                print(f"Expected: valid=True, num_triangles=2")
                print(f"Got:      valid={hw_valid}, num_triangles={hw_tris}")
                print(f"\nVertex inside bits: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
                print(f"Inside count: {int(dut.vertex_inside_count.value)}")
                continue

            # Get all hardware output vertices (6 for quad split case)
            hw_vertices = [
                # First triangle
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
                 fixed_12_12_to_float(dut.clipped_v2_w_o.value.signed_integer)),
                # Second triangle
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
            ]

            # Generate reference result
            ref_vertices, ref_num_triangles, ref_valid = clip_triangle_float(
                vertices[0][0], vertices[0][1], vertices[0][2], vertices[0][3],
                vertices[1][0], vertices[1][1], vertices[1][2], vertices[1][3],
                vertices[2][0], vertices[2][1], vertices[2][2], vertices[2][3],
                plane_normal[0], plane_normal[1], plane_normal[2], plane_offset
            )

            # Compare the results
            if len(hw_vertices) != len(ref_vertices):
                mismatches += 1
                print("\n==============================================")
                print(f"\n[ERROR] Vertex count mismatch @ test {test_idx}")
                print(f"Expected {len(ref_vertices)} vertices, got {len(hw_vertices)}")
                print("==============================================\n")
            else:
                for i, (hw_v, ref_v) in enumerate(zip(hw_vertices, ref_vertices)):
                    if not compare_vertices(hw_v, ref_v, TOL):
                        mismatches += 1
                        print("\n==============================================")
                        print(f"[ERROR] Vertex {i} mismatch @ test {test_idx}")
                        print("\nInput Triangle:")
                        print("---------------")
                        for j, v in enumerate(vertices):
                            print(f"V{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        
                        print("\nPlane Equation:")
                        print("--------------")
                        print(f"Normal: ({plane_normal[0]:.3f}, {plane_normal[1]:.3f}, {plane_normal[2]:.3f})")
                        print(f"Offset: {plane_offset:.3f}")

                        print("\nVertex Classification:")
                        print("--------------------")
                        print(f"Inside configuration: {inside_config}")
                        print(f"vertex_inside bits: {bin(dut.vertex_inside.value)[2:].zfill(3)}")
                        print(f"vertex_inside_count: {int(dut.vertex_inside_count.value)}")

                        print("\nMismatched Vertex:")
                        print("----------------")
                        print(f"Index: {i}")
                        print(f"Reference: ({ref_v[0]:.3f}, {ref_v[1]:.3f}, {ref_v[2]:.3f}, {ref_v[3]:.3f})")
                        print(f"Hardware:  ({hw_v[0]:.3f}, {hw_v[1]:.3f}, {hw_v[2]:.3f}, {hw_v[3]:.3f})")
                        print(f"Diff:     ({abs(ref_v[0]-hw_v[0]):.3f}, {abs(ref_v[1]-hw_v[1]):.3f}, "
                              f"{abs(ref_v[2]-hw_v[2]):.3f}, {abs(ref_v[3]-hw_v[3]):.3f})")

                        print("\nAll Output Vertices:")
                        print("-----------------")
                        print("First Triangle:")
                        for j in range(3):
                            v = hw_vertices[j]
                            print(f"Out{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        print("Second Triangle:")
                        for j in range(3, 6):
                            v = hw_vertices[j]
                            print(f"Out{j}: ({v[0]:.3f}, {v[1]:.3f}, {v[2]:.3f}, {v[3]:.3f})")
                        print("==============================================\n")
                        break  # Break after first mismatch for clarity

            # Wait until we're back in IDLE before next test
            while dut.curr_state.value != 0:
                await RisingEdge(dut.clk_i)

    print(f"\nTest completed: {mismatches} mismatch(es) in {NUM_TESTS} tests.")
    assert mismatches == 0, f"{mismatches} mismatch(es) found."

