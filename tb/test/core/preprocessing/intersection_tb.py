import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np

from test import intersection_12_4

#
# Fixed-point REF model that does NOT mimic 16-bit saturation
# (same intersection logic, but no forced 16-bit container)
#
def intersection_reference_fixedpoint(
    v1_x_12_4, v1_y_12_4, v1_z_12_4, v1_w_12_4,
    v2_x_12_4, v2_y_12_4, v2_z_12_4, v2_w_12_4,
    plane_a_12_4, plane_b_12_4, plane_c_12_4, plane_d_12_4
):
    """
    All inputs are in "12.4" notionally, but we do NOT clip/saturate to 16 bits here.
    """

    def mul_12_4(a, b):
        # No clipping to 16 bits; Python ints can expand arbitrarily
        # a,b in 12.4 => product is effectively 24.8 => shift right by 4
        return (a * b) >> 4

    # 1) Calculate numerator in 24.8 format
    num_24_8 = mul_12_4(plane_a_12_4, v1_x_12_4)
    num_24_8 += mul_12_4(plane_b_12_4, v1_y_12_4)
    num_24_8 += mul_12_4(plane_c_12_4, v1_z_12_4)
    num_24_8 += mul_12_4(plane_d_12_4, v1_w_12_4)

    # 2) Negate and shift left by 8 => 16.16 format
    num_16_16 = (-num_24_8) << 8

    # 3) Compute deltas
    dx_12_4 = v2_x_12_4 - v1_x_12_4
    dy_12_4 = v2_y_12_4 - v1_y_12_4
    dz_12_4 = v2_z_12_4 - v1_z_12_4
    dw_12_4 = v2_w_12_4 - v1_w_12_4

    # 4) Calculate denominator in 24.8, then shift left by 8 => 16.16
    den_24_8 = mul_12_4(plane_a_12_4, dx_12_4)
    den_24_8 += mul_12_4(plane_b_12_4, dy_12_4)
    den_24_8 += mul_12_4(plane_c_12_4, dz_12_4)
    den_24_8 += mul_12_4(plane_d_12_4, dw_12_4)
    den_16_16 = den_24_8 << 8

    # 5) Compute t in 16.16
    if den_16_16 == 0:
        t_16_16 = 0
    else:
        t_16_16 = num_16_16 // den_16_16

    def mul_t_16_16_by_12_4(t_16_16, val_12_4):
        # 16.16 * 12.4 => 28.20 => shift right 16 => 12.4
        return (t_16_16 * val_12_4) >> 16

    ix_12_4 = v1_x_12_4 + mul_t_16_16_by_12_4(t_16_16, dx_12_4)
    iy_12_4 = v1_y_12_4 + mul_t_16_16_by_12_4(t_16_16, dy_12_4)
    iz_12_4 = v1_z_12_4 + mul_t_16_16_by_12_4(t_16_16, dz_12_4)
    iw_12_4 = v1_w_12_4 + mul_t_16_16_by_12_4(t_16_16, dw_12_4)

    return (ix_12_4, iy_12_4, iz_12_4, iw_12_4)


#
# Remove 16-bit clipping for float->12.4
#
def float_to_fixed_12_4(value):
    """
    Convert float -> "12.4", but DO NOT clip to 16 bits.
    Python int can exceed [-32768, 32767].
    """
    return int(round(value * 16.0))

def fixed_12_4_to_float(val_fixed):
    """
    Convert integer in "12.4" back to float.
    NO sign-extension to 16 bits => we treat val_fixed as a normal Python int.
    """
    return val_fixed / 16.0


@cocotb.test()
async def test_intersection(dut):
    """
    Cocotb test for intersection.sv module, but does NOT clip
    intermediate or final values to 16 bits in the Python model.
    """
    # Start the clock
    clock = Clock(dut.clk_i, 10, units='ns')
    cocotb.start_soon(clock.start())

    test_iters = 1000
    print(f"Running intersection tests with {test_iters} random iterations.\n")

    # Reset-like behavior
    dut.start_i.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk_i)

    MIN_VAL = -1500.0
    MAX_VAL = 1500.0

    mismatches = 0
    failed_iterations = []

    diffs_x, diffs_y = [], []
    diffs_z, diffs_w = [], []

    for test_count in tqdm(range(test_iters), desc="Testing Intersection"):
        # Random floats
        v1_xf = np.random.uniform(MIN_VAL, MAX_VAL)
        v1_yf = np.random.uniform(MIN_VAL, MAX_VAL)
        v1_zf = np.random.uniform(MIN_VAL, MAX_VAL)
        v1_wf = np.random.uniform(MIN_VAL, MAX_VAL)

        v2_xf = np.random.uniform(MIN_VAL, MAX_VAL)
        v2_yf = np.random.uniform(MIN_VAL, MAX_VAL)
        v2_zf = np.random.uniform(MIN_VAL, MAX_VAL)
        v2_wf = np.random.uniform(MIN_VAL, MAX_VAL)

        plane_af = np.random.uniform(MIN_VAL, MAX_VAL)
        plane_bf = np.random.uniform(MIN_VAL, MAX_VAL)
        plane_cf = np.random.uniform(MIN_VAL, MAX_VAL)
        plane_df = np.random.uniform(MIN_VAL, MAX_VAL)

        # Convert floats -> "12.4" (no clip)
        fx_v1_x = float_to_fixed_12_4(v1_xf)
        fx_v1_y = float_to_fixed_12_4(v1_yf)
        fx_v1_z = float_to_fixed_12_4(v1_zf)
        fx_v1_w = float_to_fixed_12_4(v1_wf)

        fx_v2_x = float_to_fixed_12_4(v2_xf)
        fx_v2_y = float_to_fixed_12_4(v2_yf)
        fx_v2_z = float_to_fixed_12_4(v2_zf)
        fx_v2_w = float_to_fixed_12_4(v2_wf)

        fx_plane_a = float_to_fixed_12_4(plane_af)
        fx_plane_b = float_to_fixed_12_4(plane_bf)
        fx_plane_c = float_to_fixed_12_4(plane_cf)
        fx_plane_d = float_to_fixed_12_4(plane_df)

        # Drive these into DUT
        dut.v1_x.value = fx_v1_x & 0xFFFF  # DUT still has 16-bit ports
        dut.v1_y.value = fx_v1_y & 0xFFFF
        dut.v1_z.value = fx_v1_z & 0xFFFF
        dut.v1_w.value = fx_v1_w & 0xFFFF

        dut.v2_x.value = fx_v2_x & 0xFFFF
        dut.v2_y.value = fx_v2_y & 0xFFFF
        dut.v2_z.value = fx_v2_z & 0xFFFF
        dut.v2_w.value = fx_v2_w & 0xFFFF

        dut.plane_a.value = fx_plane_a & 0xFFFF
        dut.plane_b.value = fx_plane_b & 0xFFFF
        dut.plane_c.value = fx_plane_c & 0xFFFF
        dut.plane_d.value = fx_plane_d & 0xFFFF

        # Start the DUT
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for done
        while not dut.done_o.value:
            await RisingEdge(dut.clk_i)

        # HW outputs are still 16-bit => sign-extend them
        hw_ix = fixed_12_4_to_float(dut.intersect_x.value.signed_integer)
        hw_iy = fixed_12_4_to_float(dut.intersect_y.value.signed_integer)
        hw_iz = fixed_12_4_to_float(dut.intersect_z.value.signed_integer)
        hw_iw = fixed_12_4_to_float(dut.intersect_w.value.signed_integer)

        # Reference: no 16-bit clipping
        ref_ix_12_4, ref_iy_12_4, ref_iz_12_4, ref_iw_12_4 = intersection_reference_fixedpoint(
            fx_v1_x, fx_v1_y, fx_v1_z, fx_v1_w,
            fx_v2_x, fx_v2_y, fx_v2_z, fx_v2_w,
            fx_plane_a, fx_plane_b, fx_plane_c, fx_plane_d
        )
        ref_ix = ref_ix_12_4 / 16.0
        ref_iy = ref_iy_12_4 / 16.0
        ref_iz = ref_iz_12_4 / 16.0
        ref_iw = ref_iw_12_4 / 16.0

        # Compare
        dx_abs = abs(hw_ix - ref_ix)
        dy_abs = abs(hw_iy - ref_iy)
        dz_abs = abs(hw_iz - ref_iz)
        dw_abs = abs(hw_iw - ref_iw)

        diffs_x.append(dx_abs)
        diffs_y.append(dy_abs)
        diffs_z.append(dz_abs)
        diffs_w.append(dw_abs)

        TOL = 5
        if (dx_abs > TOL) or (dy_abs > TOL) or (dz_abs > TOL) or (dw_abs > TOL):
            mismatches += 1
            failed_iterations.append(test_count)
            print(f"\n[ERROR] Mismatch @ iteration {test_count}")
            print(f"  HW  = ({hw_ix:.4f}, {hw_iy:.4f}, {hw_iz:.4f}, {hw_iw:.4f})")
            print(f"  REF = ({ref_ix:.4f}, {ref_iy:.4f}, {ref_iz:.4f}, {ref_iw:.4f})")

    print(f"\nTest completed: {mismatches} mismatches out of {test_iters}.")
    if mismatches > 0:
        print(f"Failed iterations: {failed_iterations}")

    # Stats
    avg_diff_x = np.mean(diffs_x) if diffs_x else 0.0
    avg_diff_y = np.mean(diffs_y) if diffs_y else 0.0
    avg_diff_z = np.mean(diffs_z) if diffs_z else 0.0
    avg_diff_w = np.mean(diffs_w) if diffs_w else 0.0

    print("\n=== Avg Absolute Differences (HW vs REF) ===")
    print(f" X: {avg_diff_x:.4f}")
    print(f" Y: {avg_diff_y:.4f}")
    print(f" Z: {avg_diff_z:.4f}")
    print(f" W: {avg_diff_w:.4f}")

    assert mismatches == 0, f"{mismatches} mismatch(es) found."

