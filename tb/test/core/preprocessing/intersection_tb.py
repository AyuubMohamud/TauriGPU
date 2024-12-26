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
    """Floating-point reference for line-plane intersection, 
    now clamping t in [0,1] to match segment logic."""
    numerator = -(a*v1_x + b*v1_y + c*v1_z + d*v1_w)
    dx = v2_x - v1_x
    dy = v2_y - v1_y
    dz = v2_z - v1_z
    dw = v2_w - v1_w
    denominator = (a*dx + b*dy + c*dz + d*dw)
    
    # Check near parallel
    if abs(denominator) < 1e-15:
        return (float('nan'), float('nan'), float('nan'), float('nan'))

    t = numerator / denominator

    # Clamp t to [0,1]
    t = max(0.0, min(1.0, t))
    return (
        v1_x + dx * t,
        v1_y + dy * t,
        v1_z + dz * t,
        v1_w + dw * t
    )

def float_to_fixed_12_12(value):
    """Convert float to 12.12 fixed point format (1 sign + 11 int + 12 frac = 24 bits)."""
    return int(round(value * 4096.0))  # 2^12 = 4096

def fixed_12_12_to_float(val_fixed):
    """Convert 12.12 fixed point back to float."""
    return val_fixed / 4096.0


@cocotb.test()
async def test_intersection(dut):
    """
    Cocotb test for intersection.sv module using floating point reference model
    and 12.12 fixed point format.
    """
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    test_iters = 1000
    print(f"Running intersection tests with {test_iters} random (segment) intersections in 12.12.\n")

    dut.start_i.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    MIN_VAL = -1280.0
    MAX_VAL = +1279.0

    mismatches = 0
    failed_iterations = []

    diffs_x, diffs_y = [], []
    diffs_z, diffs_w = [], []

    rng = np.random.default_rng()

    for test_count in tqdm(range(test_iters), desc="Testing Intersection"):
        
        # Pick random v1, v2
        v1_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v1_wf = 1.0

        v2_xf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_yf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_zf = rng.uniform(MIN_VAL, MAX_VAL)
        v2_wf = 1.0

        # Pick random t in [0,1]
        t_rand = rng.uniform(0.0, 1.0)

        # Intersection p = v1 + t*(v2 - v1)
        px = v1_xf + t_rand * (v2_xf - v1_xf)
        py = v1_yf + t_rand * (v2_yf - v1_yf)
        pz = v1_zf + t_rand * (v2_zf - v1_zf)
        pw = v1_wf + t_rand * (v2_wf - v1_wf)

        # Define a random plane that passes through p
        while True:
            plane_a0 = rng.uniform(-1.0, 1.0)
            plane_b0 = rng.uniform(-1.0, 1.0)
            plane_c0 = rng.uniform(-1.0, 1.0)
            plane_d0 = rng.uniform(-1.0, 1.0)
            norm = abs(plane_a0) + abs(plane_b0) + abs(plane_c0) + abs(plane_d0)
            if norm > 0.001:
                break

        plane_a = plane_a0
        plane_b = plane_b0
        plane_c = plane_c0

        if abs(pw) < 1e-6:
            continue

        # Solve plane_d so plane passes through (px,py,pz,pw)
        plane_d = - (plane_a * px + plane_b * py + plane_c * pz) / pw

        # Check not parallel
        dot_line = (plane_a * (v2_xf - v1_xf)
                    + plane_b * (v2_yf - v1_yf)
                    + plane_c * (v2_zf - v1_zf)
                    + plane_d * (v2_wf - v1_wf))
        if abs(dot_line) < 1e-6:
            continue

        # Convert to 12.12
        fx_v1_x = float_to_fixed_12_12(v1_xf)
        fx_v1_y = float_to_fixed_12_12(v1_yf)
        fx_v1_z = float_to_fixed_12_12(v1_zf)
        fx_v1_w = float_to_fixed_12_12(v1_wf)

        fx_v2_x = float_to_fixed_12_12(v2_xf)
        fx_v2_y = float_to_fixed_12_12(v2_yf)
        fx_v2_z = float_to_fixed_12_12(v2_zf)
        fx_v2_w = float_to_fixed_12_12(v2_wf)

        fx_plane_a = float_to_fixed_12_12(plane_a)
        fx_plane_b = float_to_fixed_12_12(plane_b)
        fx_plane_c = float_to_fixed_12_12(plane_c)
        fx_plane_d = float_to_fixed_12_12(plane_d)

        # DUT inputs: 24 bits wide => mask with 0xFFFFFF
        dut.v1_x.value = fx_v1_x & 0xFFFFFF
        dut.v1_y.value = fx_v1_y & 0xFFFFFF
        dut.v1_z.value = fx_v1_z & 0xFFFFFF
        dut.v1_w.value = fx_v1_w & 0xFFFFFF

        dut.v2_x.value = fx_v2_x & 0xFFFFFF
        dut.v2_y.value = fx_v2_y & 0xFFFFFF
        dut.v2_z.value = fx_v2_z & 0xFFFFFF
        dut.v2_w.value = fx_v2_w & 0xFFFFFF

        dut.plane_a.value = fx_plane_a & 0xFFFFFF
        dut.plane_b.value = fx_plane_b & 0xFFFFFF
        dut.plane_c.value = fx_plane_c & 0xFFFFFF
        dut.plane_d.value = fx_plane_d & 0xFFFFFF

        # Start the DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done signal
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # HW outputs in 12.12
        hw_ix = fixed_12_12_to_float(dut.intersect_x.value.signed_integer)
        hw_iy = fixed_12_12_to_float(dut.intersect_y.value.signed_integer)
        hw_iz = fixed_12_12_to_float(dut.intersect_z.value.signed_integer)
        hw_iw = fixed_12_12_to_float(dut.intersect_w.value.signed_integer)

        # Reference result
        ref_ix, ref_iy, ref_iz, ref_iw = intersection_float(
            v1_xf, v1_yf, v1_zf, v1_wf,
            v2_xf, v2_yf, v2_zf, v2_wf,
            plane_a, plane_b, plane_c, plane_d
        )

        # If reference is NaN, skip
        if any(np.isnan(x) for x in (ref_ix, ref_iy, ref_iz, ref_iw)):
            continue

        # Compare
        dx_abs = abs(hw_ix - ref_ix)
        dy_abs = abs(hw_iy - ref_iy)
        dz_abs = abs(hw_iz - ref_iz)
        dw_abs = abs(hw_iw - ref_iw)

        diffs_x.append(dx_abs)
        diffs_y.append(dy_abs)
        diffs_z.append(dz_abs)
        diffs_w.append(dw_abs)

        TOL = 10
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

    assert mismatches < 10, f"{mismatches} mismatch(es) found."
