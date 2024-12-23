import numpy as np

#
# --- Floating-point version (reference) ---
#
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


#
# --- Intersection: 16.16 ---
#
def intersection_16_16(
    fx_v1_x, fx_v1_y, fx_v1_z, fx_v1_w,
    fx_v2_x, fx_v2_y, fx_v2_z, fx_v2_w,
    fx_plane_a, fx_plane_b, fx_plane_c, fx_plane_d
):
    """
    16.16 fixed-point intersection calculation.
    (Upper 16 bits = integer; lower 16 bits = fraction.)
    """
    def mul_16_16(a, b):
        return (a * b) >> 16

    num_16_16 = mul_16_16(fx_plane_a, fx_v1_x)
    num_16_16 += mul_16_16(fx_plane_b, fx_v1_y)
    num_16_16 += mul_16_16(fx_plane_c, fx_v1_z)
    num_16_16 += mul_16_16(fx_plane_d, fx_v1_w)
    num_16_16 = -num_16_16

    dx_16_16 = fx_v2_x - fx_v1_x
    dy_16_16 = fx_v2_y - fx_v1_y
    dz_16_16 = fx_v2_z - fx_v1_z
    dw_16_16 = fx_v2_w - fx_v1_w

    den_16_16 = mul_16_16(fx_plane_a, dx_16_16)
    den_16_16 += mul_16_16(fx_plane_b, dy_16_16)
    den_16_16 += mul_16_16(fx_plane_c, dz_16_16)
    den_16_16 += mul_16_16(fx_plane_d, dw_16_16)

    if den_16_16 == 0:
        # Parallel or near-parallel
        t_16_16 = 0
    else:
        # Multiply numerator by 2^16 before dividing
        t_16_16 = (num_16_16 << 16) // den_16_16

    ix_16_16 = fx_v1_x + mul_16_16(t_16_16, dx_16_16)
    iy_16_16 = fx_v1_y + mul_16_16(t_16_16, dy_16_16)
    iz_16_16 = fx_v1_z + mul_16_16(t_16_16, dz_16_16)
    iw_16_16 = fx_v1_w + mul_16_16(t_16_16, dw_16_16)

    return (ix_16_16, iy_16_16, iz_16_16, iw_16_16)


#
# --- Intersection: 12.4 ---
#
def intersection_12_4(
    fx_v1_x, fx_v1_y, fx_v1_z, fx_v1_w,
    fx_v2_x, fx_v2_y, fx_v2_z, fx_v2_w,
    fx_plane_a, fx_plane_b, fx_plane_c, fx_plane_d
):
    """
    12.4 fixed-point intersection calculation.
    (Upper 12 bits = integer; lower 4 bits = fraction.)
    """
    def mul_12_4(a, b):
        # Shift right by 4 bits after multiplication
        return (a * b) >> 4

    # Compute numerator = -(plane dot v1)
    num_12_4 = mul_12_4(fx_plane_a, fx_v1_x)
    num_12_4 += mul_12_4(fx_plane_b, fx_v1_y)
    num_12_4 += mul_12_4(fx_plane_c, fx_v1_z)
    num_12_4 += mul_12_4(fx_plane_d, fx_v1_w)
    num_12_4 = -num_12_4

    # Direction deltas
    dx_12_4 = fx_v2_x - fx_v1_x
    dy_12_4 = fx_v2_y - fx_v1_y
    dz_12_4 = fx_v2_z - fx_v1_z
    dw_12_4 = fx_v2_w - fx_v1_w

    # Denominator = plane dot (v2 - v1)
    den_12_4 = mul_12_4(fx_plane_a, dx_12_4)
    den_12_4 += mul_12_4(fx_plane_b, dy_12_4)
    den_12_4 += mul_12_4(fx_plane_c, dz_12_4)
    den_12_4 += mul_12_4(fx_plane_d, dw_12_4)

    if den_12_4 == 0:
        # Parallel or near-parallel
        t_12_4 = 0
    else:
        # Multiply numerator by 2^4 before dividing
        t_12_4 = (num_12_4 << 4) // den_12_4

    # Intersection point
    ix_12_4 = fx_v1_x + mul_12_4(t_12_4, dx_12_4)
    iy_12_4 = fx_v1_y + mul_12_4(t_12_4, dy_12_4)
    iz_12_4 = fx_v1_z + mul_12_4(t_12_4, dz_12_4)
    iw_12_4 = fx_v1_w + mul_12_4(t_12_4, dw_12_4)

    return (ix_12_4, iy_12_4, iz_12_4, iw_12_4)


# ---------------------------------------------------------------------
# Conversion Helpers
# ---------------------------------------------------------------------

def float_to_16_16(value):
    """
    Convert a float to 16.16 fixed-point.
    (lowest 16 bits = fraction; 1 unit = 65536)
    """
    return int(round(value * 65536.0))  # 2^16 = 65536

def fixed_16_16_to_float(val_fixed):
    """
    Convert a 16.16 fixed-point to float.
    """
    return val_fixed / 65536.0

def float_to_12_4(value):
    """
    Convert a float to 12.4 fixed-point.
    (lowest 4 bits = fraction; 1 unit = 16)
    """
    return int(round(value * 16.0))  # 2^4 = 16

def fixed_12_4_to_float(val_fixed):
    """
    Convert a 12.4 fixed-point to float.
    """
    return val_fixed / 16.0


# ---------------------------------------------------------------------
# Compare implementations
# ---------------------------------------------------------------------

def compare_implementations(num_tests=500, min_val=-2048.0, max_val=2048.0):
    """
    Compare these methods:
      1) float (reference)
      2) 16.16
      3) 12.4
    using a random set of intersection tests in [min_val, max_val].
    """
    np.random.seed(44)
    
    # Error dictionaries
    errors_16_16 = {'x': [], 'y': [], 'z': [], 'w': []}
    errors_12_4 =  {'x': [], 'y': [], 'z': [], 'w': []}
    
    for _ in range(num_tests):
        points = np.random.uniform(min_val, max_val, 8)  # v1, v2
        plane = np.random.uniform(min_val, max_val, 4)   # plane a, b, c, d
        
        # Reference (float)
        float_result = intersection_float(*points[:4], *points[4:], *plane)

        # 16.16
        pts_16_16 = [float_to_16_16(v) for v in points]
        pln_16_16 = [float_to_16_16(v) for v in plane]
        res_16_16 = intersection_16_16(
            *pts_16_16[:4], *pts_16_16[4:], *pln_16_16
        )
        res_16_16f = [fixed_16_16_to_float(x) for x in res_16_16]

        # 12.4
        pts_12_4 = [float_to_12_4(v) for v in points]
        pln_12_4 = [float_to_12_4(v) for v in plane]
        res_12_4 = intersection_12_4(
            *pts_12_4[:4], *pts_12_4[4:], *pln_12_4
        )
        res_12_4f = [fixed_12_4_to_float(x) for x in res_12_4]

        # If float_result is not parallel (NaN)
        if not any(np.isnan(x) for x in float_result):
            eps = 1e-15
            for i, coord in enumerate(['x', 'y', 'z', 'w']):
                denom = abs(float_result[i]) + eps

                err_16_16 = abs(res_16_16f[i] - float_result[i]) / denom * 100
                errors_16_16[coord].append(err_16_16)

                err_12_4 = abs(res_12_4f[i] - float_result[i]) / denom * 100
                errors_12_4[coord].append(err_12_4)

        else:
            # For parallel/near-parallel => store large placeholder error
            for coord in ['x', 'y', 'z', 'w']:
                errors_16_16[coord].append(9999.0)
                errors_12_4[coord].append(9999.0)
    
    # Print results
    print("=== Comparison of Fixed-Point Implementations vs. Floating Point ===")
    print(f"Number of tests: {num_tests}")
    print(f"Value range: [{min_val}, {max_val}]")

    # Helper functions
    def avg_err(errors):
        return np.mean(errors) if len(errors) else 0.0

    def max_err(errors):
        return np.max(errors) if len(errors) else 0.0

    # Print average errors
    print("\nAverage Relative Errors (%):")
    print("Coord |   16.16   |    12.4   ")
    print("----------------------------------")
    for coord in ['x', 'y', 'z', 'w']:
        a_16_16 = avg_err(errors_16_16[coord])
        a_12_4  = avg_err(errors_12_4[coord])
        print(f"{coord:4} | {a_16_16:9.4f} | {a_12_4:9.4f}")

    # Print maximum errors
    print("\nMaximum Relative Errors (%):")
    print("Coord |   16.16   |    12.4   ")
    print("----------------------------------")
    for coord in ['x', 'y', 'z', 'w']:
        m_16_16 = max_err(errors_16_16[coord])
        m_12_4  = max_err(errors_12_4[coord])
        print(f"{coord:4} | {m_16_16:9.4f} | {m_12_4:9.4f}")


if __name__ == "__main__":
    compare_implementations(num_tests=5000, min_val=-2047.0, max_val=2048.0)
