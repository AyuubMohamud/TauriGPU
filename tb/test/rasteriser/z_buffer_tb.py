import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from tqdm import tqdm
import numpy as np
import sys

from mods.logging_mods import *
from mods.quantization_mods import *

from ref_model.z_buffer_ref import SoftwareZBuffer

@cocotb.test()
async def test_new_z_buffer(dut):
    pass
'''
buffer_base_address <- 0 here
test different addresses for the valid buffer range
use pixel_x and pixel_y to calculate the address

optimisation using subtration
pixel_z_i - value in z_buffer --> check for value
'''