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