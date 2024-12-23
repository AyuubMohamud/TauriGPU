import shutil
import argparse
from pathlib import Path
from datetime import datetime

from single_test import single_test
from mods.exception_mods import *


def move_file(test_dir: Path, compute_unit_name: str, module_under_test: str) -> None:
    """
    Copies the current dump.vcd file into the waves folder as 'dump.vcd',
    also saves a copy with a timestamp for record keeping.
    
    Args:
        test_dir (Path): Path to the test directory (e.g., tb/test).
        compute_unit_name (str): The folder path (relative to rtl/) 
                                 that contains the module_under_test.sv (e.g., core/preprocessing).
        module_under_test (str): The module name (matches the -n argument).
    """
    waves_dir = test_dir / 'waves'
    waves_dir.mkdir(parents=True, exist_ok=True)  # Ensure waves directory exists

    # Paths for the current dump.vcd and the destination dump.vcd
    src_vcd = test_dir / compute_unit_name / 'dump.vcd'
    dest_vcd = waves_dir / 'dump.vcd'

    # ----------------------------------------------------------------
    # CHANGE HERE: use copy instead of move
    # ----------------------------------------------------------------
    shutil.copy(str(src_vcd), str(dest_vcd))

    # Generate a unique filename based on the current timestamp and module
    timestamped_filename = datetime.now().strftime('%y%m%d_%H%M%S_') + module_under_test + '.vcd'
    timestamped_vcd = waves_dir / timestamped_filename

    # Copy the dump.vcd to create a timestamped version
    shutil.copy(str(dest_vcd), str(timestamped_vcd))

    # Log the timestamped file name for record keeping
    record_file = waves_dir / 'record.txt'
    with record_file.open('a') as record:
        record.write(f'{timestamped_filename}\n')  # Append the timestamped file name

    print(f'Waveform {timestamped_filename} saved and recorded.')


def main():
    parser = argparse.ArgumentParser(description='Cocotb Verilator runner')
    parser.add_argument('-n', '--name', type=str, required=True, 
                        help='Name of the module being tested (without .sv extension)')
    parser.add_argument('-t', '--trace', type=int, required=True, 
                        help='Enable trace waveform (1 or 0)')
    args = parser.parse_args()

    module_under_test = args.name
    enable_trace = bool(args.trace)

    # Derive project directories
    current_dir = Path(__file__).parent        # e.g., ./tb
    project_dir = current_dir.parent           # e.g., ./ (top-level or ./rtl parent)
    rtl_dir = project_dir / 'rtl'              # Root of all RTL subfolders
    test_dir = current_dir / 'test'
    sim_build_dir = current_dir / 'sim_build'

    # ----------------------------------------------------------------
    # 1) SEARCH for {module_under_test}.sv under the ./rtl directory
    # ----------------------------------------------------------------
    sv_file_path = None
    for candidate in rtl_dir.rglob(f'{module_under_test}.sv'):
        if candidate.is_file():
            sv_file_path = candidate
            break

    if sv_file_path is None:
        raise FileNotFoundError(
            f"Cannot find {module_under_test}.sv anywhere under {rtl_dir}."
        )

    # Extract the 'compute unit' folder path relative to rtl/
    # e.g. if found /path/to/rtl/core/preprocessing/intersection.sv
    # => compute_unit_name = "core/preprocessing"
    compute_unit_path = sv_file_path.parent.relative_to(rtl_dir)
    compute_unit_name = str(compute_unit_path)

    # ----------------------------------------------------------------
    # 2) SEARCH for {module_under_test}_tb.py under the ./test folder
    # ----------------------------------------------------------------
    py_testbench_file = None
    for candidate in test_dir.rglob(f'{module_under_test}_tb.py'):
        if candidate.is_file():
            py_testbench_file = candidate
            break

    if py_testbench_file is None:
        print(f"Warning: Cannot find {module_under_test}_tb.py under {test_dir}.")
        test_module_name = f"{module_under_test}_tb"
    else:
        test_module_name = py_testbench_file.stem
        print(f"Found Python testbench at: {py_testbench_file}")
        print(f"Using single-level module name = '{test_module_name}'")

    # ----------------------------------------------------------------
    # Cleanup Phase
    # ----------------------------------------------------------------
    # ----------------------------------------------------------------
    # CHANGE HERE: remove the dump.vcd unlink portion
    # ----------------------------------------------------------------
    # dump_vcd = test_dir / compute_unit_name / 'dump.vcd'
    # if dump_vcd.exists():
    #     dump_vcd.unlink()
    # (No more unlinking! We keep the original dump.vcd.)

    for item in current_dir.glob('sim_build.*'):
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)
    print('Removed all previous sim_build.* files/directories.')

    # Ensure sim_build_dir exists
    sim_build_dir.mkdir(parents=True, exist_ok=True)

    # Construct the path to the module .sv and relevant paths
    module_path = sv_file_path
    component_path = sv_file_path.parent
    test_files_dir = test_dir / compute_unit_name
    module_params = {}

    # ----------------------------------------------------------------
    # 3) Invoke the single_test function
    # ----------------------------------------------------------------
    single_test(
        test_id=1,
        dependencies=[compute_unit_name],
        top_module=module_under_test,
        test_module=test_module_name,  # Use flattened naming approach
        module_params=module_params,
        module_path=module_path,
        component_path=component_path,
        sim_build_dir=sim_build_dir,
        test_files_dir=test_files_dir,
        enable_trace=enable_trace,
    )

    # 4) Copy the VCD file after simulation completes if tracing is enabled
    if enable_trace:
        move_file(test_dir, compute_unit_name, module_under_test)

if __name__ == '__main__':
    main()
