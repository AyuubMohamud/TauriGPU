
def float_to_fixed_12_12(value):
    """Convert float to 12.12 fixed point format (1 sign + 11 int + 12 frac = 24 bits)."""
    return int(round(value * 4096.0))  # 2^12 = 4096

def fixed_12_12_to_float(val_fixed):
    """Convert 12.12 fixed point back to float."""
    return val_fixed / 4096.0

def clip_triangle_float(
    v0_x, v0_y, v0_z, v0_w,
    v1_x, v1_y, v1_z, v1_w,
    v2_x, v2_y, v2_z, v2_w,
    plane_normal_x, plane_normal_y, plane_normal_z, plane_offset
):
    """Floating-point reference for triangle clipping against a plane."""
    
    # Calculate dot products for classification
    dot_v0 = v0_x * plane_normal_x + v0_y * plane_normal_y + v0_z * plane_normal_z + v0_w * plane_offset
    dot_v1 = v1_x * plane_normal_x + v1_y * plane_normal_y + v1_z * plane_normal_z + v1_w * plane_offset
    dot_v2 = v2_x * plane_normal_x + v2_y * plane_normal_y + v2_z * plane_normal_z + v2_w * plane_offset
    
    # Classify vertices
    inside = [dot_v0 >= 0, dot_v1 >= 0, dot_v2 >= 0]
    inside_count = sum(inside)

    # Compute intersections if needed
    def compute_intersection(v1, v2):
        x1, y1, z1, w1 = v1
        x2, y2, z2, w2 = v2
        
        numerator = -(plane_normal_x * x1 + plane_normal_y * y1 + plane_normal_z * z1 + plane_offset * w1)
        dx = x2 - x1
        dy = y2 - y1
        dz = z2 - z1
        dw = w2 - w1
        denominator = (plane_normal_x * dx + plane_normal_y * dy + plane_normal_z * dz + plane_offset * dw)
        
        if abs(denominator) < 1e-15:
            return (x1, y1, z1, w1)  # Return first vertex if parallel
            
        t = numerator / denominator
        t = max(0.0, min(1.0, t))  # Clamp to [0,1]
        
        return (
            x1 + dx * t,
            y1 + dy * t,
            z1 + dz * t,
            w1 + dw * t
        )

    if inside_count == 0:
        # All vertices outside - triangle is culled
        return [], 0, False
        
    elif inside_count == 3:
        # All vertices inside - no clipping needed
        return [
            (v0_x, v0_y, v0_z, v0_w),
            (v1_x, v1_y, v1_z, v1_w),
            (v2_x, v2_y, v2_z, v2_w)
        ], 1, True
                
    elif inside_count == 1:
        # One vertex inside -> new single triangle
        if inside[0]:  # v0 inside
            i1 = compute_intersection((v0_x, v0_y, v0_z, v0_w), (v1_x, v1_y, v1_z, v1_w))
            i2 = compute_intersection((v0_x, v0_y, v0_z, v0_w), (v2_x, v2_y, v2_z, v2_w))
            return [(v0_x, v0_y, v0_z, v0_w), i1, i2], 1, True
        elif inside[1]:  # v1 inside
            i1 = compute_intersection((v1_x, v1_y, v1_z, v1_w), (v2_x, v2_y, v2_z, v2_w))
            i2 = compute_intersection((v1_x, v1_y, v1_z, v1_w), (v0_x, v0_y, v0_z, v0_w))
            return [(v1_x, v1_y, v1_z, v1_w), i1, i2], 1, True
        else:  # v2 inside
            i1 = compute_intersection((v2_x, v2_y, v2_z, v2_w), (v0_x, v0_y, v0_z, v0_w))
            i2 = compute_intersection((v2_x, v2_y, v2_z, v2_w), (v1_x, v1_y, v1_z, v1_w))
            return [(v2_x, v2_y, v2_z, v2_w), i1, i2], 1, True
            
    else:  # inside_count == 2
        # Two vertices inside -> up to two triangles
        if not inside[0]:  # v0 outside
            i1 = compute_intersection((v1_x, v1_y, v1_z, v1_w), (v0_x, v0_y, v0_z, v0_w))
            i2 = compute_intersection((v2_x, v2_y, v2_z, v2_w), (v0_x, v0_y, v0_z, v0_w))
            return [
                (v1_x, v1_y, v1_z, v1_w),
                (v2_x, v2_y, v2_z, v2_w),
                i1,
                (v2_x, v2_y, v2_z, v2_w),
                i2,
                i1
            ], 2, True
        elif not inside[1]:  # v1 outside
            i1 = compute_intersection((v2_x, v2_y, v2_z, v2_w), (v1_x, v1_y, v1_z, v1_w))
            i2 = compute_intersection((v0_x, v0_y, v0_z, v0_w), (v1_x, v1_y, v1_z, v1_w))
            return [
                (v2_x, v2_y, v2_z, v2_w),
                (v0_x, v0_y, v0_z, v0_w),
                i1,
                (v0_x, v0_y, v0_z, v0_w),
                i2,
                i1
            ], 2, True
        else:  # v2 outside
            i1 = compute_intersection((v0_x, v0_y, v0_z, v0_w), (v2_x, v2_y, v2_z, v2_w))
            i2 = compute_intersection((v1_x, v1_y, v1_z, v1_w), (v2_x, v2_y, v2_z, v2_w))
            return [
                (v0_x, v0_y, v0_z, v0_w),
                (v1_x, v1_y, v1_z, v1_w),
                i1,
                (v0_x, v0_y, v0_z, v0_w),
                i1,
                i2
            ], 2, True

def compare_vertices(hw_vertex, ref_vertex, tolerance=0.1):
    """Compare hardware and reference vertices within tolerance."""
    for hw_val, ref_val in zip(hw_vertex, ref_vertex):
        if abs(hw_val - ref_val) > tolerance:
            return False
    return True