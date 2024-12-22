import numpy as np

def fix_to_float(val, width, frac_bits):
    """
    Convert signed fixed-point 'val' to Python float.
    val is a 2's complement integer occupying 'width' bits, 
    with 'frac_bits' fractional bits.
    """
    # If the sign bit is set, interpret val as negative.
    sign_mask = 1 << (width - 1)
    if val & sign_mask:
        # Convert from two's complement
        val = val - (1 << width)

    return float(val) / (1 << frac_bits)

def float_to_fix(fval, width, frac_bits):
    """
    Convert Python float 'fval' into signed fixed-point integer
    with 'width' bits total and 'frac_bits' fractional bits.
    """
    scaled = int(round(fval * (1 << frac_bits)))

    # Wrap into two's complement range:
    # e.g., for width=32, valid range is [-2^(31), 2^(31)-1].
    # We'll modulo by 2^width for wrapping:
    mask = (1 << width) - 1
    scaled = scaled & mask

    return scaled

def intersection_ref(
    v1_x, v1_y, v1_z, v1_w,
    v2_x, v2_y, v2_z, v2_w,
    plane_a, plane_b, plane_c, plane_d,
    vertex_width=32,
    frac_bits=16
):
    """
    Computes the intersection point of the line from v1 to v2
    with the plane (a*x + b*y + c*z + d*w = 0), in floating-point,
    then converts back to fixed-point to compare against hardware.

    The module calculates:
      t_num = -(a*v1.x + b*v1.y + c*v1.z + d*v1.w)
      t_den = a*(v2.x - v1.x) + b*(v2.y - v1.y)
              + c*(v2.z - v1.z) + d*(v2.w - v1.w)
      t = t_num / t_den
      intersect = v1 + t*(v2 - v1)
    """
    # Convert inputs from fixed to float
    fv1_x = fix_to_float(v1_x, vertex_width, frac_bits)
    fv1_y = fix_to_float(v1_y, vertex_width, frac_bits)
    fv1_z = fix_to_float(v1_z, vertex_width, frac_bits)
    fv1_w = fix_to_float(v1_w, vertex_width, frac_bits)

    fv2_x = fix_to_float(v2_x, vertex_width, frac_bits)
    fv2_y = fix_to_float(v2_y, vertex_width, frac_bits)
    fv2_z = fix_to_float(v2_z, vertex_width, frac_bits)
    fv2_w = fix_to_float(v2_w, vertex_width, frac_bits)

    fa = fix_to_float(plane_a, vertex_width, frac_bits)
    fb = fix_to_float(plane_b, vertex_width, frac_bits)
    fc = fix_to_float(plane_c, vertex_width, frac_bits)
    fd = fix_to_float(plane_d, vertex_width, frac_bits)

    # Compute t in float
    t_num = -(fa*fv1_x + fb*fv1_y + fc*fv1_z + fd*fv1_w)
    t_den = (fa*(fv2_x - fv1_x) +
             fb*(fv2_y - fv1_y) +
             fc*(fv2_z - fv1_z) +
             fd*(fv2_w - fv1_w))

    # To avoid division by zero, we can check if t_den is near zero
    if abs(t_den) < 1e-15:
        # If the denominator is nearly zero, it might mean no intersection or parallel.
        # One might define a fallback; here, just set t=0.
        t = 0.0
    else:
        t = t_num / t_den

    # Compute intersection in float
    ix = fv1_x + t * (fv2_x - fv1_x)
    iy = fv1_y + t * (fv2_y - fv1_y)
    iz = fv1_z + t * (fv2_z - fv1_z)
    iw = fv1_w + t * (fv2_w - fv1_w)

    # Convert intersection back to fixed-point
    fix_ix = float_to_fix(ix, vertex_width, frac_bits)
    fix_iy = float_to_fix(iy, vertex_width, frac_bits)
    fix_iz = float_to_fix(iz, vertex_width, frac_bits)
    fix_iw = float_to_fix(iw, vertex_width, frac_bits)

    return fix_ix, fix_iy, fix_iz, fix_iw
