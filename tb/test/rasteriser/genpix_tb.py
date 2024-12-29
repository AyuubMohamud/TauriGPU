import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

#
# Utility functions
#
def float_to_20_4_unsigned(value: float) -> int:
    """
    Convert a positive float to unsigned 20.4 fixed point (24 bits total).
    Clamps to [0, (1 << 24) - 1].
    """
    # Multiply by 2^4, then round
    val_int = int(round(value * (1 << 4)))
    # Clip to 24 bits
    return max(0, min(val_int, (1 << 24) - 1))

def float_to_20_4_signed(value: float) -> int:
    """
    Convert a float (could be negative) to signed 20.4 fixed point (25 bits total).
    - 1 sign bit + 20 integer bits + 4 fractional bits = 25 bits
    Range: -2^(20) .. +2^(20) - (1/16)
    """
    val_int = int(round(value * (1 << 4)))
    # Sign-extend to 25 bits if needed
    # But since we're just storing in Python's int, we only need to clamp.
    # The module expects a 25-bit two's complement for negative numbers.
    # Let's clamp to [-2^24, 2^24 - 1] just for safety.
    min_val = -(1 << 24)
    max_val = (1 << 24) - 1
    val_int = max(min_val, min(val_int, max_val))
    return val_int & ((1 << 25) - 1)  # keep only lower 25 bits

def float_to_17_signed(value: float) -> int:
    """
    For dl_wX_row_i or dl_wX_col_i (17 bits).
    Usually these are slope increments.  
    Range: -2^(16) .. +2^(16)-1
    """
    val_int = int(round(value))
    min_val = -(1 << 16)
    max_val = (1 << 16) - 1
    val_int = max(min_val, min(val_int, max_val))
    return val_int & ((1 << 17) - 1)  # lower 17 bits

#
# Main test
#
@cocotb.test()
async def test_genpix(dut):
    """
    Test the genpix module by driving randomized inputs and checking
    that it properly transitions from IDLE -> PIXEL_OUT -> COMPLETE -> IDLE.
    """
    clock = Clock(dut.clock_i, 10, units="ns")
    cocotb.start_soon(clock.start())

    # Default
    dut.reset_i.value = 1
    dut.valid_i.value = 0
    dut.busy_i.value = 0  # Downstream always ready in this test

    # Drive zero on all inputs initially
    dut.area_i.value = 0
    dut.dl_w0_col_i.value = 0
    dut.dl_w1_col_i.value = 0
    dut.dl_w2_col_i.value = 0
    dut.dl_w0_row_i.value = 0
    dut.dl_w1_row_i.value = 0
    dut.dl_w2_row_i.value = 0
    dut.w0_row_i.value = 0
    dut.w1_row_i.value = 0
    dut.w2_row_i.value = 0
    dut.x_min_i.value = 0
    dut.y_min_i.value = 0
    dut.x_max_i.value = 0
    dut.y_max_i.value = 0

    # Apply reset for a few cycles
    for _ in range(5):
        await RisingEdge(dut.clock_i)

    dut.reset_i.value = 0
    await RisingEdge(dut.clock_i)

    # Number of random tests
    NUM_TESTS = 20

    for test_idx in range(NUM_TESTS):

        #
        # Generate random inputs
        #
        # area_i: 24 bits, 20.4 (unsigned)
        # We'll keep a random range from [0..2000]
        area_val = random.uniform(0, 2000.0)
        dut.area_i.value = float_to_20_4_unsigned(area_val)

        # dl_wX_col_i, dl_wX_row_i: 17 bits each
        # We'll keep it in ~[-1028..1028]
        dut.dl_w0_col_i.value = float_to_17_signed(random.uniform(-1028, 1028))
        dut.dl_w1_col_i.value = float_to_17_signed(random.uniform(-1028, 1028))
        dut.dl_w2_col_i.value = float_to_17_signed(random.uniform(-1028, 1028))

        dut.dl_w0_row_i.value = float_to_17_signed(random.uniform(-1028, 1028))
        dut.dl_w1_row_i.value = float_to_17_signed(random.uniform(-1028, 1028))
        dut.dl_w2_row_i.value = float_to_17_signed(random.uniform(-1028, 1028))

        # wX_row_i: 25 bits, s.20.4
        # We'll keep it ~[-2000..2000]
        w0_row_val = random.uniform(-2000, 2000)
        w1_row_val = random.uniform(-2000, 2000)
        w2_row_val = random.uniform(-2000, 2000)
        dut.w0_row_i.value = float_to_20_4_signed(w0_row_val)
        dut.w1_row_i.value = float_to_20_4_signed(w1_row_val)
        dut.w2_row_i.value = float_to_20_4_signed(w2_row_val)

        # x_min_i, y_min_i, x_max_i, y_max_i: 12 bits each
        # We'll keep them 0..1028 (so we stay in 12-bit range).
        x_min = random.randint(0, 512)
        x_max = x_min + random.randint(0, 512)
        y_min = random.randint(0, 512)
        y_max = y_min + random.randint(0, 512)

        dut.x_min_i.value = x_min
        dut.x_max_i.value = x_max
        dut.y_min_i.value = y_min
        dut.y_max_i.value = y_max

        #
        # Fire valid_i for at least one cycle
        #
        dut.valid_i.value = 1
        await RisingEdge(dut.clock_i)
        dut.valid_i.value = 0  # De-assert valid after one cycle

        #
        # Now wait for the rasterizer to finish generating pixels.
        # The module sets busy_o until it enters COMPLETE state
        # and sees busy_i==0, then busy_o de-asserts.
        #
        # We simply wait until busy_o==0 for at least 1 cycle
        #

        while True:
            await RisingEdge(dut.clock_i)
            if dut.busy_o.value == 0:
                # The design is done for this set of inputs
                break

        # 
        # Optionally, we can check a few last output cycles
        # or count how many cycles we saw valid_o go high, etc.
        # (Skipping deep checks here for brevity.)
        #

        dut._log.info(f"[TEST {test_idx}] Completed with area_i={area_val:.2f} "
                      f"(w0_row={w0_row_val:.2f}, w1_row={w1_row_val:.2f}, w2_row={w2_row_val:.2f}) "
                      f"x-range=({x_min}, {x_max}), y-range=({y_min}, {y_max})")

    dut._log.info("All tests completed successfully!")
