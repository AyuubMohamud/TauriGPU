from numpy import random, clip


def generate_random_hex(width, range_, size, distribution='uniform'):
    """ Generate a list of random hex numbers.

    :param width: Bit width of the generated hex numbers
    :param range_: Range of the generated hex numbers (tuple of two integers, start and end)
    :param size: Sample size, i.e., length of the returned list
    :param distribution: (Optional) Distribution type for random integers. Can be 'uniform' or 'normal'
    :return: rand_hex_list - List of random hex numbers """
    
    # Initialize the random number generator
    rng = random.default_rng()
    
    # Determine the maximum value based on the bit width
    max_value = 2**width - 1
    
    # Ensure the provided range does not exceed the bit width limit
    if range_[1] > max_value:
        raise ValueError(f"The upper bound of the range exceeds the max value for the given bit width ({max_value}).")
    
    # Generate random integers based on the selected distribution
    if distribution == 'uniform':
        rand_ints = rng.integers(low=range_[0], high=range_[1], size=size)
    elif distribution == 'normal':
        mean = (range_[0] + range_[1]) / 2
        stddev = (range_[1] - range_[0]) / 6  # Assuming approx 99.7% of values in this range
        rand_ints = rng.normal(loc=mean, scale=stddev, size=size).astype(int)
        rand_ints = clip(rand_ints, range_[0], range_[1])  # Ensure values stay within range
    else:
        raise ValueError("Unsupported distribution. Choose 'uniform' or 'normal'.")
    
    # Convert the generated integers to hexadecimal
    rand_hex_list = [int(num) for num in rand_ints]
    
    return rand_hex_list
