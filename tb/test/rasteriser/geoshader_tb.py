import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.binary import BinaryValue
import numpy as np
from tqdm import tqdm

from reference_model import GeoshaderReference, Vertex, Triangle, Plane

class TestVector:
    def __init__(self, triangle, planes):
        self.triangle = triangle
        self.planes = planes

def generate_special_test_cases():
    """Generate special test cases that cover edge conditions"""
    special_cases = []
    
    # Case 1: Triangle completely inside all planes
    triangle = Triangle(
        v0=Vertex(x=0.0, y=0.0, z=0.0, w=1.0),
        v1=Vertex(x=0.1, y=0.1, z=0.1, w=1.0),
        v2=Vertex(x=-0.1, y=0.1, z=-0.1, w=1.0)
    )
    planes = [Plane(a=1.0, b=0.0, c=0.0, d=1.0) for _ in range(6)]  # All planes far from triangle
    special_cases.append(TestVector(triangle, planes))
    
    # Case 2: Triangle completely outside one plane
    triangle = Triangle(
        v0=Vertex(x=2.0, y=0.0, z=0.0, w=1.0),
        v1=Vertex(x=2.1, y=0.1, z=0.1, w=1.0),
        v2=Vertex(x=2.2, y=-0.1, z=-0.1, w=1.0)
    )
    planes = [Plane(a=1.0, b=0.0, c=0.0, d=-1.0)]  # First plane culls triangle
    planes.extend([Plane(a=1.0, b=0.0, c=0.0, d=1.0) for _ in range(5)])
    special_cases.append(TestVector(triangle, planes))
    
    # Case 3: Triangle with one vertex inside, two outside
    triangle = Triangle(
        v0=Vertex(x=0.0, y=0.0, z=0.0, w=1.0),
        v1=Vertex(x=2.0, y=0.0, z=0.0, w=1.0),
        v2=Vertex(x=2.0, y=2.0, z=0.0, w=1.0)
    )
    planes = [Plane(a=1.0, b=0.0, c=0.0, d=1.0)]  # First plane clips triangle
    planes.extend([Plane(a=1.0, b=0.0, c=0.0, d=2.0) for _ in range(5)])
    special_cases.append(TestVector(triangle, planes))
    
    # Case 4: Triangle with degenerate vertices (zero w)
    triangle = Triangle(
        v0=Vertex(x=0.1, y=0.1, z=0.1, w=0.0),
        v1=Vertex(x=0.2, y=0.2, z=0.2, w=0.0),
        v2=Vertex(x=0.3, y=0.3, z=0.3, w=0.0)
    )
    planes = [Plane(a=1.0, b=0.0, c=0.0, d=1.0) for _ in range(6)]
    special_cases.append(TestVector(triangle, planes))
    
    return special_cases

def generate_test_vectors(num_vectors=1000):
    """Generate random test vectors and include special test cases"""
    vectors = []
    
    for _ in range(num_vectors):
        # Generate random triangle
        triangle = Triangle(
            v0=Vertex(
                x=np.random.uniform(-1, 1),
                y=np.random.uniform(-1, 1),
                z=np.random.uniform(-1, 1),
                w=np.random.uniform(0, 1)
            ),
            v1=Vertex(
                x=np.random.uniform(-1, 1),
                y=np.random.uniform(-1, 1),
                z=np.random.uniform(-1, 1),
                w=np.random.uniform(0, 1)
            ),
            v2=Vertex(
                x=np.random.uniform(-1, 1),
                y=np.random.uniform(-1, 1),
                z=np.random.uniform(-1, 1),
                w=np.random.uniform(0, 1)
            )
        )
        
        # Generate random planes
        planes = []
        for _ in range(6):
            # Generate normalized plane normal
            normal = np.random.uniform(-1, 1, 3)
            normal = normal / np.linalg.norm(normal)
            
            planes.append(Plane(
                a=normal[0],
                b=normal[1],
                c=normal[2],
                d=np.random.uniform(-1, 1)
            ))
            
        vectors.append(TestVector(triangle, planes))
        
    # Add special test cases
    vectors.extend(generate_special_test_cases())
    return vectors

async def reset_dut(dut):
    """Reset the DUT"""
    dut.start_i.value = 0
    
    for i in range(6):
        dut.plane_a_i[i].value = 0
        dut.plane_b_i[i].value = 0
        dut.plane_c_i[i].value = 0
        dut.plane_d_i[i].value = 0
    
    await Timer(20, units='ns')

async def drive_input_triangle(dut, triangle, ref_model):
    """Drive input triangle vertices to DUT"""
    # Quantize vertices
    v0 = ref_model.quantize_vertex(triangle.v0)
    v1 = ref_model.quantize_vertex(triangle.v1)
    v2 = ref_model.quantize_vertex(triangle.v2)
    
    # Drive values
    dut.v0_x_i.value = v0.x
    dut.v0_y_i.value = v0.y
    dut.v0_z_i.value = v0.z
    dut.v0_w_i.value = v0.w
    
    dut.v1_x_i.value = v1.x
    dut.v1_y_i.value = v1.y
    dut.v1_z_i.value = v1.z
    dut.v1_w_i.value = v1.w
    
    dut.v2_x_i.value = v2.x
    dut.v2_y_i.value = v2.y
    dut.v2_z_i.value = v2.z
    dut.v2_w_i.value = v2.w

async def drive_planes(dut, planes, ref_model):
    """Drive clipping planes to DUT"""
    for i, plane in enumerate(planes):
        # Quantize plane coefficients
        p = ref_model.quantize_plane(plane)
        
        # Drive values
        dut.plane_a_i[i].value = p.a
        dut.plane_b_i[i].value = p.b
        dut.plane_c_i[i].value = p.c
        dut.plane_d_i[i].value = p.d

def verify_output_triangle(dut, expected_triangles, ref_model):
    """Verify DUT output matches reference model"""
    if len(expected_triangles) == 0:
        assert dut.valid_o.value == 0, "Triangle should be culled"
        return
        
    assert dut.valid_o.value == 1, "Triangle should be valid"
    
    # Get output triangle vertices
    out_v0 = Vertex(
        x=dut.v0_x_o.value.signed_integer,
        y=dut.v0_y_o.value.signed_integer,
        z=dut.v0_z_o.value.signed_integer,
        w=dut.v0_w_o.value.signed_integer
    )
    
    out_v1 = Vertex(
        x=dut.v1_x_o.value.signed_integer,
        y=dut.v1_y_o.value.signed_integer,
        z=dut.v1_z_o.value.signed_integer,
        w=dut.v1_w_o.value.signed_integer
    )
    
    out_v2 = Vertex(
        x=dut.v2_x_o.value.signed_integer,
        y=dut.v2_y_o.value.signed_integer,
        z=dut.v2_z_o.value.signed_integer,
        w=dut.v2_w_o.value.signed_integer
    )
    
    # Compare with expected
    # Note: May need to implement more sophisticated comparison due to
    # fixed-point arithmetic differences between SW and HW
    epsilon = 1.0  # Allow 1 LSB difference
    
    def compare_vertices(v1, v2):
        return (abs(v1.x - v2.x) <= epsilon and
                abs(v1.y - v2.y) <= epsilon and
                abs(v1.z - v2.z) <= epsilon and
                abs(v1.w - v2.w) <= epsilon)
    
    # Find matching triangle in expected output
    found_match = False
    for exp_tri in expected_triangles:
        if (compare_vertices(out_v0, exp_tri.v0) and
            compare_vertices(out_v1, exp_tri.v1) and
            compare_vertices(out_v2, exp_tri.v2)):
            found_match = True
            break
            
    assert found_match, "Output triangle doesn't match any expected triangle"

@cocotb.test()
async def test_geoshader(dut):
    """Test the geoshader module"""
    
    # Create clock
    clock = Clock(dut.clk_i, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Create reference model
    ref_model = GeoshaderReference()
    
    # Generate test vectors
    test_vectors = generate_test_vectors(num_vectors=1000)
    
    # Run tests
    for vector in tqdm(test_vectors, desc="Testing geoshader"):
        # Reset DUT
        await reset_dut(dut)
        
        # Drive inputs
        await drive_input_triangle(dut, vector.triangle, ref_model)
        await drive_planes(dut, vector.planes, ref_model)
        
        # Start processing
        dut.start_i.value = 1
        await RisingEdge(dut.clk_i)
        dut.start_i.value = 0

        # Wait for processing to complete
        while dut.done_o.value == 0:
            await RisingEdge(dut.clk_i)

        # Get reference model result
        expected_triangles = ref_model.process_triangle(vector.triangle, vector.planes)

        # Verify output
        try:
            verify_output_triangle(dut, expected_triangles, ref_model)
        except AssertionError as e:
            # Log detailed failure information
            print("\nTest failure details:")
            print(f"Input triangle: {vector.triangle}")
            print("\nClipping planes:")
            for i, plane in enumerate(vector.planes):
                print(f"Plane {i}: {plane}")
            print("\nExpected triangles:")
            for i, tri in enumerate(expected_triangles):
                print(f"Triangle {i}: {tri}")
            print("\nDUT outputs:")
            print(f"v0: ({dut.v0_x_o.value}, {dut.v0_y_o.value}, {dut.v0_z_o.value}, {dut.v0_w_o.value})")
            print(f"v1: ({dut.v1_x_o.value}, {dut.v1_y_o.value}, {dut.v1_z_o.value}, {dut.v1_w_o.value})")
            print(f"v2: ({dut.v2_x_o.value}, {dut.v2_y_o.value}, {dut.v2_z_o.value}, {dut.v2_w_o.value})")
            print(f"valid_o: {dut.valid_o.value}")
            print(f"num_triangles_o: {dut.num_triangles_o.value}")
            raise

    print(f"\nAll tests passed successfully!")