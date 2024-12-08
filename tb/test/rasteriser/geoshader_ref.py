import numpy as np
from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class Vertex:
    x: float
    y: float
    z: float
    w: float

@dataclass
class Triangle:
    v0: Vertex
    v1: Vertex
    v2: Vertex

@dataclass
class Plane:
    a: float  # normal.x
    b: float  # normal.y
    c: float  # normal.z
    d: float  # offset

class GeoshaderReference:
    def __init__(self, vertex_width=32, num_planes=6):
        self.vertex_width = vertex_width
        self.num_planes = num_planes
        
    def clip_against_plane(self, triangle: Triangle, plane: Plane) -> List[Triangle]:
        """Clip a triangle against a plane, returning 0, 1, or 2 triangles"""
        
        # Calculate dot products to determine which vertices are inside
        dots = []
        vertices = [triangle.v0, triangle.v1, triangle.v2]
        for v in vertices:
            dot = plane.a * v.x + plane.b * v.y + plane.c * v.z + plane.d * v.w
            dots.append(dot >= 0)
            
        inside_count = sum(dots)
        
        if inside_count == 0:
            return []  # Triangle is completely outside
            
        if inside_count == 3:
            return [triangle]  # Triangle is completely inside
            
        # Need to clip - calculate intersection points
        intersections = []
        for i in range(3):
            if dots[i] != dots[(i + 1) % 3]:
                v1 = vertices[i]
                v2 = vertices[(i + 1) % 3]
                t = self._compute_intersection_t(v1, v2, plane)
                intersections.append(self._interpolate_vertex(v1, v2, t))
                
        if inside_count == 1:
            # Find the single inside vertex
            inside_idx = dots.index(True)
            inside_vertex = vertices[inside_idx]
            # Create single triangle using inside vertex and two intersection points
            return [Triangle(inside_vertex, intersections[0], intersections[1])]
            
        else:  # inside_count == 2
            # Find the single outside vertex
            outside_idx = dots.index(False)
            v1_idx = (outside_idx + 1) % 3
            v2_idx = (outside_idx + 2) % 3
            # Create two triangles from the quad
            t1 = Triangle(vertices[v1_idx], vertices[v2_idx], intersections[0])
            t2 = Triangle(vertices[v2_idx], intersections[1], intersections[0])
            return [t1, t2]
    
    def _compute_intersection_t(self, v1: Vertex, v2: Vertex, plane: Plane) -> float:
        """Compute parametric intersection point between line segment and plane"""
        x1, y1, z1, w1 = v1.x, v1.y, v1.z, v1.w
        x2, y2, z2, w2 = v2.x, v2.y, v2.z, v2.w
        
        num = -(plane.a * x1 + plane.b * y1 + plane.c * z1 + plane.d * w1)
        den = plane.a * (x2 - x1) + plane.b * (y2 - y1) + plane.c * (z2 - z1) + plane.d * (w2 - w1)
        
        if abs(den) < 1e-6:  # Avoid division by zero
            return 0.0
            
        return num / den
        
    def _interpolate_vertex(self, v1: Vertex, v2: Vertex, t: float) -> Vertex:
        """Linearly interpolate between two vertices"""
        return Vertex(
            x=v1.x + t * (v2.x - v1.x),
            y=v1.y + t * (v2.y - v1.y),
            z=v1.z + t * (v2.z - v1.z),
            w=v1.w + t * (v2.w - v1.w)
        )
        
    def process_triangle(self, triangle: Triangle, planes: List[Plane]) -> List[Triangle]:
        """Process a triangle through all clipping planes"""
        current_triangles = [triangle]
        
        for plane in planes:
            next_triangles = []
            for tri in current_triangles:
                clipped = self.clip_against_plane(tri, plane)
                next_triangles.extend(clipped)
            current_triangles = next_triangles
            
        return current_triangles

    def quantize_vertex(self, v: Vertex) -> Vertex:
        """Quantize vertex coordinates to match hardware precision"""
        scale = (1 << (self.vertex_width - 1)) - 1
        return Vertex(
            x=int(np.clip(v.x * scale, -scale, scale)),
            y=int(np.clip(v.y * scale, -scale, scale)),
            z=int(np.clip(v.z * scale, -scale, scale)),
            w=int(np.clip(v.w * scale, -scale, scale))
        )

    def quantize_plane(self, p: Plane) -> Plane:
        """Quantize plane coefficients to match hardware precision"""
        scale = (1 << (self.vertex_width - 1)) - 1
        return Plane(
            a=int(np.clip(p.a * scale, -scale, scale)),
            b=int(np.clip(p.b * scale, -scale, scale)),
            c=int(np.clip(p.c * scale, -scale, scale)),
            d=int(np.clip(p.d * scale, -scale, scale))
        )