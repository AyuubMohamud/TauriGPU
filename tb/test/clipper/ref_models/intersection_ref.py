import numpy as np

def compute_intersection(v1, v2, plane):
    """
    Compute the intersection point between a line segment (v1 to v2) and a plane.

    Parameters:
    - v1: Tuple or list of (x, y, z, w) for the first vertex.
    - v2: Tuple or list of (x, y, z, w) for the second vertex.
    - plane: Tuple or list of (A, B, C, D) coefficients for the plane equation Ax + By + Cz + Dw = 0.

    Returns:
    - intersect: Tuple of (x, y, z, w) for the intersection point if it exists.
    - valid: Boolean indicating whether an intersection exists.
    """
    v1 = np.array(v1, dtype=np.float64)
    v2 = np.array(v2, dtype=np.float64)
    plane = np.array(plane, dtype=np.float64)

    # Plane coefficients
    A, B, C, D = plane

    # Compute numerator and denominator for t
    t_num = -(A * v1[0] + B * v1[1] + C * v1[2] + D * v1[3])
    t_den = A * (v2[0] - v1[0]) + B * (v2[1] - v1[1]) + C * (v2[2] - v1[2]) + D * (v2[3] - v1[3])

    # Check for parallelism
    if t_den == 0:
        if t_num == 0:
            # The line lies on the plane
            return v1.tolist(), True
        else:
            # No intersection
            return (0, 0, 0, 0), False

    t = t_num / t_den

    # Compute intersection point
    intersect = v1 + t * (v2 - v1)

    return intersect.tolist(), True
