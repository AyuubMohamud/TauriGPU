import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np

def intersection_float(
    v1_x, v1_y, v1_z, v1_w,
    v2_x, v2_y, v2_z, v2_w,
    a, b, c, d
):
    """Floating-point implementation (reference)"""
    numerator = -(a*v1_x + b*v1_y + c*v1_z + d*v1_w)
    dx = v2_x - v1_x
    dy = v2_y - v1_y
    dz = v2_z - v1_z
    dw = v2_w - v1_w
    denominator = (a*dx + b*dy + c*dz + d*dw)

    if abs(denominator) < 1e-15:
        # Parallel or nearly parallel => no valid intersection
        return (float('nan'), float('nan'), float('nan'), float('nan'))

    t = numerator / denominator
    return (
        v1_x + dx * t,
        v1_y + dy * t,
        v1_z + dz * t,
        v1_w + dw * t
    )
def float_to_fixed_12_8(value):
    """Convert float to 12.8 fixed point format"""
    return int(round(value * 256.0))  # 2^8 = 256

def fixed_12_8_to_float(val_fixed):
    """Convert 12.8 fixed point back to float"""
    return val_fixed / 256.0

@cocotb.test()
async def test_intersection(dut):
    """
    Cocotb test for intersection.sv module using floating point reference model
    and 12.8 fixed point format.

    Now we ONLY generate test cases where the plane truly intersects
    the *segment* between v1 and v2. So t is guaranteed in [0,1].
    """
    # Start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    test_iters = 1000
    print(f"Running intersection tests with {test_iters} random (segment) intersections.\n")

    # Reset-like behavior
    dut.start_i.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    MIN_VAL = -2048.0
    MAX_VAL =  2048.0

    mismatches = 0
    failed_iterations = []

    diffs_x, diffs_y = [], []
    diffs_z, diffs_w = [], []

    rng = np.random.default_rng()  # recommended random generator

    for test_count in tqdm(range(test_iters), desc="Testing Intersection"):
        
        # 1) Pick random v1, v2 in [-2048,+2048]
        v1_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_zf = rng.uniform(MIN_VAL, MAX_VAL)
        # you might choose w=1 in typical 3D coordinates, or random
        v1_wf = 1.0  # or rng.uniform(MIN_VAL, MAX_VAL)

        v2_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_wf = 1.0  # or rng.uniform(MIN_VAL, MAX_VAL)

        # 2) Pick random t in [0,1]
        t_rand = rng.random()  # uniform 0..1

        # 3) Intersection p = v1 + t*(v2 - v1)
        px = v1_xf + t_rand*(v2_xf - v1_xf)
        py = v1_yf + t_rand*(v2_yf - v1_yf)
        pz = v1_zf + t_rand*(v2_zf - v1_zf)
        pw = v1_wf + t_rand*(v2_wf - v1_wf)

        # 4) Define a random plane that passes through p:
        #    plane: plane_a*x + plane_b*y + plane_c*z + plane_d*w = 0
        #    We'll pick a random normal vector (plane_a, plane_b, plane_c, plane_d')
        #    Then solve plane_d = - (a*px + b*py + c*pz + d'*pw)/w_coefficient
        #
        #    For "typical" 3D usage with w=1, it's often plane_a*x + plane_b*y + plane_c*z + plane_d = 0.
        #    But here we can do 4D, so let's do the generic approach:
        
        # Step A: random normal
        # We want to ensure it's not the zero vector. We'll keep picking until magnitude is ok.
        while True:
            # range smaller to reduce extremes, or keep [-1,1]
            plane_a0 = rng.uniform(-1.0, 1.0)
            plane_b0 = rng.uniform(-1.0, 1.0)
            plane_c0 = rng.uniform(-1.0, 1.0)
            plane_d0 = rng.uniform(-1.0, 1.0)
            norm = abs(plane_a0) + abs(plane_b0) + abs(plane_c0) + abs(plane_d0)
            if norm > 0.001:
                break

        # Step B: solve for plane_d so it satisfies plane eqn at p => 0.
        #    plane_a*x + plane_b*y + plane_c*z + plane_d*w = 0
        # Let (a,b,c,d0) be the normal so far. We want d = ?

        # We want:  a*px + b*py + c*pz + d*w = 0
        # =>        d = -(a*px + b*py + c*pz + d0*pw) / w_coeff
        # But in standard 4D plane form: plane_d is the 4th coefficient. So let's rename carefully.
        # Actually let's do it simpler: We'll treat plane_d0 as "the 4th normal coefficient" itself.
        # So the equation is: a*px + b*py + c*pz + d0*pw = 0
        # We'll rename plane_d0 as plane_d, and "pw" is just pw.

        # Evaluate partial = a*px + b*py + c*pz + d0*pw
        partial = (plane_a0 * px) + (plane_b0 * py) + (plane_c0 * pz) + (plane_d0 * pw)
        # If partial == 0 => plane is already passing through p. If not, we can re-scale or re-pick.
        # An easier way is to simply re-scale the entire plane's normal so partial=0. We'll do that
        # by shifting plane_d so the plane eqn is satisfied. But we want to keep "d0" as is?

        # Actually, in a homogeneous sense:
        #   plane eqn: a*x + b*y + c*z + d*w = 0
        # We want (px,py,pz,pw) in it => a*px + b*py + c*pz + d*pw = 0
        # => d = -(a*px + b*py + c*pz)/pw  (assuming pw != 0)
        # Let's do that. We won't use plane_d0. We'll compute a fresh "plane_d" from (a,b,c).
        # Let's rename plane_d0 => plane_w to avoid confusion.

        plane_a = plane_a0
        plane_b = plane_b0
        plane_c = plane_c0
        plane_w = plane_d0  # we'll just ignore this if we treat w=1 typical
        # We'll recalc the real plane_d for the eqn a*x + b*y + c*z + d*w=0:
        #    d = -(a*px + b*py + c*pz) / pw    if pw != 0
        # If pw==0, we do a different approach, or skip.
        if abs(pw) < 1e-6:
            # skip or pick new v1,v2
            continue

        plane_d = -(plane_a*px + plane_b*py + plane_c*pz) / pw
        # Now (plane_a, plane_b, plane_c, plane_d) is guaranteed to pass through p.

        # Step C: ensure not parallel => plane . (v2 - v1) != 0
        dot_line = (plane_a*(v2_xf - v1_xf)
                    + plane_b*(v2_yf - v1_yf)
                    + plane_c*(v2_zf - v1_zf)
                    + plane_d*(v2_wf - v1_wf))
        if abs(dot_line) < 1e-6:
            # skip, re-pick
            continue
        
        # Now we have a plane that definitely intersects the line at t_rand in [0,1].
        # We can proceed to test the hardware.

        # Convert floats to 12.8 fixed point for DUT input
        fx_v1_x = float_to_fixed_12_8(v1_xf)
        fx_v1_y = float_to_fixed_12_8(v1_yf)
        fx_v1_z = float_to_fixed_12_8(v1_zf)
        fx_v1_w = float_to_fixed_12_8(v1_wf)

        fx_v2_x = float_to_fixed_12_8(v2_xf)
        fx_v2_y = float_to_fixed_12_8(v2_yf)
        fx_v2_z = float_to_fixed_12_8(v2_zf)
        fx_v2_w = float_to_fixed_12_8(v2_wf)

        fx_plane_a = float_to_fixed_12_8(plane_a)
        fx_plane_b = float_to_fixed_12_8(plane_b)
        fx_plane_c = float_to_fixed_12_8(plane_c)
        fx_plane_d = float_to_fixed_12_8(plane_d)

        # Drive DUT inputs (20-bit port width)
        dut.v1_x.value = fx_v1_x & 0xFFFFF
        dut.v1_y.value = fx_v1_y & 0xFFFFF
        dut.v1_z.value = fx_v1_z & 0xFFFFF
        dut.v1_w.value = fx_v1_w & 0xFFFFF

        dut.v2_x.value = fx_v2_x & 0xFFFFF
        dut.v2_y.value = fx_v2_y & 0xFFFFF
        dut.v2_z.value = fx_v2_z & 0xFFFFF
        dut.v2_w.value = fx_v2_w & 0xFFFFF

        dut.plane_a.value = fx_plane_a & 0xFFFFF
        dut.plane_b.value = fx_plane_b & 0xFFFFF
        dut.plane_c.value = fx_plane_c & 0xFFFFF
        dut.plane_d.value = fx_plane_d & 0xFFFFF

        # Start the DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done signal
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # Get DUT outputs and convert to float
        hw_ix = fixed_12_8_to_float(dut.intersect_x.value.signed_integer)
        hw_iy = fixed_12_8_to_float(dut.intersect_y.value.signed_integer)
        hw_iz = fixed_12_8_to_float(dut.intersect_z.value.signed_integer)
        hw_iw = fixed_12_8_to_float(dut.intersect_w.value.signed_integer)

        # Reference result
        ref_ix, ref_iy, ref_iz, ref_iw = intersection_float(
            v1_xf, v1_yf, v1_zf, v1_wf,
            v2_xf, v2_yf, v2_zf, v2_wf,
            plane_a, plane_b, plane_c, plane_d
        )

        # If reference is NaN (unlikely now), skip
        if any(np.isnan(x) for x in (ref_ix, ref_iy, ref_iz, ref_iw)):
            continue

        # Compare results
        dx_abs = abs(hw_ix - ref_ix)
        dy_abs = abs(hw_iy - ref_iy)
        dz_abs = abs(hw_iz - ref_iz)
        dw_abs = abs(hw_iw - ref_iw)

        diffs_x.append(dx_abs)
        diffs_y.append(dy_abs)
        diffs_z.append(dz_abs)
        diffs_w.append(dw_abs)

        TOL = 20  ############### you may adjust tolerance
        if (dx_abs > TOL) or (dy_abs > TOL) or (dz_abs > TOL) or (dw_abs > TOL):
            mismatches += 1
            failed_iterations.append(test_count)
            print(f"\n[ERROR] Mismatch @ iteration {test_count}")
            print(f"  t_rand = {t_rand:.3f}")
            print(f"  HW  = ({hw_ix:.6f}, {hw_iy:.6f}, {hw_iz:.6f}, {hw_iw:.6f})")
            print(f"  REF = ({ref_ix:.6f}, {ref_iy:.6f}, {ref_iz:.6f}, {ref_iw:.6f})")
            print(f"  Diff = ({dx_abs:.6f}, {dy_abs:.6f}, {dz_abs:.6f}, {dw_abs:.6f})")

    print(f"\nTest completed: {mismatches} mismatches out of {test_iters}.")

    # Statistics
    avg_diff_x = np.mean(diffs_x) if diffs_x else 0.0
    avg_diff_y = np.mean(diffs_y) if diffs_y else 0.0
    avg_diff_z = np.mean(diffs_z) if diffs_z else 0.0
    avg_diff_w = np.mean(diffs_w) if diffs_w else 0.0

    print("\n=== Avg Absolute Differences (HW vs REF) ===")
    print(f" X: {avg_diff_x:.6f}")
    print(f" Y: {avg_diff_y:.6f}")
    print(f" Z: {avg_diff_z:.6f}")
    print(f" W: {avg_diff_w:.6f}")

    # Optionally fail if mismatches
    assert mismatches == 0, f"{mismatches} mismatch(es) found."
