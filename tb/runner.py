import shutil
import argparse
from pathlib import Path
from datetime import datetime

from single_test import single_test
from mods.exception_mods import *

def move_file(test_dir: Path, compute_unit_name: str, module_under_test: str) -> None:
    """
    Moves the current dump.vcd file into the waves folder as 'dump.vcd',
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

    # Move the current dump.vcd to the waves folder as "dump.vcd"
    shutil.move(str(src_vcd), str(dest_vcd))

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

    # 1) SEARCH FOR {module_under_test}.sv under the ./rtl directory
    #    This will locate the path to the .sv file and extract the subdirectory as compute_unit_name
    sv_file_path = None
    for candidate in rtl_dir.rglob(f'{module_under_test}.sv'):
        if candidate.is_file():
            sv_file_path = candidate
            break

    if sv_file_path is None:
        raise FileNotFoundError(
            f"Cannot find {module_under_test}.sv anywhere under {rtl_dir}."
        )

    # 2) Extract the 'compute unit' folder path relative to rtl/
    #    e.g., if sv_file_path = /path/to/rtl/core/preprocessing/intersection.sv
    #    then compute_unit_name = "core/preprocessing"
    compute_unit_path = sv_file_path.parent.relative_to(rtl_dir)
    compute_unit_name = str(compute_unit_path)  # e.g., core/preprocessing

    # Remove previous sim_build.* and dump.vcd
    dump_vcd = test_dir / compute_unit_name / 'dump.vcd'
    if dump_vcd.exists():
        dump_vcd.unlink()

    for item in current_dir.glob('sim_build.*'):
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)
    print('Removed all previous sim_build.* files/directories.')

    # Ensure sim_build_dir exists
    sim_build_dir.mkdir(parents=True, exist_ok=True)

    # 3) Construct the path to the module for simulation
    module_path = sv_file_path  # We already know the .sv file exact path
    component_path = sv_file_path.parent        # folder containing the .sv
    test_files_dir = test_dir / compute_unit_name

    # Additional module parameters can be specified here
    module_params = {}

    # 4) Invoke the single_test function
    single_test(
        test_id=1,
        dependencies=[compute_unit_name],
        top_module=module_under_test,
        test_module=f'{module_under_test}_tb',
        module_params=module_params,
        module_path=module_path,
        component_path=component_path,
        sim_build_dir=sim_build_dir,
        test_files_dir=test_files_dir,
        enable_trace=enable_trace,
    )

    # 5) Move the VCD file after simulation completes if tracing is enabled
    if enable_trace:
        move_file(test_dir, compute_unit_name, module_under_test)

if __name__ == '__main__':
    main()
