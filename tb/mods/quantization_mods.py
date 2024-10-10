import numpy as np


def fixed_point_to_float(fixed_point_value:list|int, width:int, frac:int, signed=True):
    """ *this function seems to be buggy with list type inputs.* 
    Written by GPT, not checked. Convert WIDTH-bit, FRAC fraction-size 
    fixed-point integer to float. 

    :param fixed_point_value: The fixed-point value as an integer (in 
            two's complement format), or a list of these values
    :param width: The total number of bits for the fixed-point representation
    :param frac_bits: The number of fractional bits
    :return: The corresponding floating-point value """
    
    width = int(width)
    frac = int(frac)
    if isinstance(fixed_point_value, list) or isinstance(fixed_point_value, np.ndarray):
        out_list = []
        for value in fixed_point_value:
            value = float(value)
            out_list.append(fixed_point_to_float(value, width, frac))
        return out_list
    else:
        fixed_point_value = int(fixed_point_value)
        # Check if the number is negative (for two's complement conversion)
        if signed and (fixed_point_value & (1 << (width - 1))):  # MSB is set (negative number)
            # Perform two's complement conversion for negative numbers
            fixed_point_value -= (1 << width)
        
        # Convert the fixed-point value to a floating-point value
        float_value = fixed_point_value / (2 ** frac)
        
        return float_value


def float_to_fixed_point(float_value:list|int, width:int, frac:int):
    """ Written by GPT, not checked. Convert a floating-point value to
    a fixed-point integer.

    :param float_value: The floating-point value to be converted,
            or a list of these values
    :param width: The total number of bits for the fixed-point representation
    :param frac: The number of fractional bits
    :return: The fixed-point value as an integer (in two's 
            complement format) """
    
    width = int(width)
    frac = int(frac)
    if isinstance(float_value, list) or isinstance(float_value, np.ndarray):
        # Recursively call itself if input is a list
        out_list = []
        for value in float_value:
            value = float(value)
            out_list.append(float_to_fixed_point(value, width, frac))
        return out_list
    else:
        float_value = float(float_value)
        # Scale the float by the number of fractional bits
        scaled_value = round(float_value * (2 ** frac))
        
        # Calculate the maximum and minimum values based on the width
        max_value = (1 << (width - 1)) - 1  # Max positive value (2^(width-1) - 1)
        min_value = -(1 << (width - 1))     # Min negative value (-2^(width-1))
        
        # Handle overflow (clip the value to fit within the bit width)
        if scaled_value > max_value:
            scaled_value = max_value
        elif scaled_value < min_value:
            scaled_value = min_value

        # Convert the scaled value to a two's complement representation if needed
        if scaled_value < 0:
            # Two's complement for negative numbers
            scaled_value = (1 << width) + scaled_value

        return scaled_value


def relative_error(a, b, threshold=0) -> float:
    """ Calculates the relative error between a and b. 
    Returns 0.0 if both inputs are 0.

    :param threshold: Returns 0 if abs(all input values) is below this value
    :returns: (a - b) / ((a + b) / 2) """

    if ((abs(a) >= threshold) or (abs(b) >= threshold)) \
        and (a != 0 or b != 0):
        if (a + b) * 2 != 0:
            return (a - b) / (a + b) * 2
        else:
            raise ZeroDivisionError(f'arg_1 = {a}, arg_2 = {b}')
    else:
        return 0.
