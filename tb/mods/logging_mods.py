from colorama import init as colorama_init
from colorama import Fore, Back, Style


colorama_init(autoreset=True)

def color_log(dut, message:str, color:str=None, log_error=False):
    """ Makes it easier to log messages in color
    Instead of `dut._log.info(Fore.GREEN + 'message' + Style.RESET_ALL)`,
    now use `color_log(dut, 'message')` 
    
    :param dut: The DUT
    :param message: (str) The message to log
    :param color: (str) colors from the `colorama` module
    :param log_error: (bool) Toggles between cocotb log INFO and ERROR
    :return: None """

    try:
        message = str(message)
        # Setting default colors
        if color == None:
            if message.startswith('Input '):
                # Input signals
                color = Fore.CYAN + Style.BRIGHT
            elif message.startswith('Output '):
                # Output from dut
                color = Fore.YELLOW + Style.BRIGHT
            elif message.startswith('Expted ') or message.startswith('Relerr '):
                # Expected output
                color = Fore.YELLOW
            elif message.startswith('Progress ('):
                # Progress report, eg 'Progress (test_alpha_compute): {counter} / {test_iters}'
                color = Fore.LIGHTMAGENTA_EX
            elif message.startswith('Running ') and ('() with' in message):
                # eg 'Running test_alpha_compute() with test_iters = {test_iters}'
                message = ' ' + message + ' '
                color = Fore.BLACK + Back.LIGHTYELLOW_EX
            else:
                # Default
                color = Fore.GREEN
        if log_error:
            dut._log.error(color + str(message) + Style.RESET_ALL)
        else:
            dut._log.info(color + str(message) + Style.RESET_ALL)
    except Exception as e:
        dut._log.error(f'Error color_logging message of type {type(message)}:\n{e}')


def log_progress(dut, test_count, test_iters, frac=10):
    """ Prints out a message to log testing progress
    
    :param dut: The DUT
    :param test_count: The current progress
    :param test_iters: How many cycles in total
    :param frac: (Optional) Logs progress n times 
    :return: None """

    if (test_count % (max(test_iters//frac, 1)) == 0) or (test_count == test_iters):
        color_log(dut, f'Progress (test_alpha_compute): {test_count} / {test_iters}')


def list_signals(dut):
    """ Prints all signals and parameters in the DUT

    :param dut: The DUT
    :return: None """

    # Iterate over all attributes in the DUT
    i = 0
    for attribute_name in dir(dut):
        # Get the attribute (signal, variable, etc.)
        attribute = getattr(dut, attribute_name)
        
        # Check if it's a signal or a variable
        if hasattr(attribute, "value"):
            i += 1
            # Print the signal name and its value in a tabular format
            color = Fore.WHITE if i % 2 else Fore.WHITE+Style.BRIGHT
            color_log(dut, f"{i}  {attribute_name:<30}  {str(attribute.value):<30}", color)
            if not bool((i+1) % 10):
                color_log(dut, '')


def get_in_out_ports(dut):
    """ Takes a DUT, returns its input / output ports and internal signals
    in 3 lists of strings.
    
    :param dut: The DUT
    :return in_ports: (list[str]) eg ['clk_i', 'resetn_i']
    :return out_ports: (list[str]) eg ['data_o', 'flag_o']
    :return internal_signals: (list[str]) eg ['intermediate_result'] """
    
    in_ports = []
    out_ports = []
    internal_signals = []
    
    # Iterate through all attributes of the DUT
    for signal_name in dir(dut):
        # Skip private or special attributes (those starting with '_')
        if signal_name.startswith('_'):
            continue
        
        # Get the signal object
        signal = getattr(dut, signal_name)
        
        # Check if it's an input, output, or internal signal
        if hasattr(signal, 'value'):
            # If the signal name ends with '_i', it's an input port
            if signal_name.endswith('_i'):
                in_ports.append(signal_name)
            # If the signal name ends with '_o', it's an output port
            elif signal_name.endswith('_o'):
                out_ports.append(signal_name)
            else:
                # Otherwise, it's considered an internal signal
                internal_signals.append(signal_name)
    
    return in_ports, out_ports, internal_signals


def print_list(lst):
    """ Prints an iterable, newline for every element. Uses python `print()`.

    :param lst: (iterable) The iterable to be printed
    :return: None """
    
    for item in lst:
        print(item)