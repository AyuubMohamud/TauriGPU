import shutil, argparse
from pathlib import Path
from datetime import datetime

from single_test import single_test
from mods.exception_mods import *

compute_unit_name = 'core/preprocessing'

def move_file(test_dir: str, module_under_test: str) -> str:
    """ Moves the current dump.vcd file into the waves folder as 'dump.vcd', 
    also saves a copy with a timestamp for record keeping. """
    
    waves_dir = test_dir / 'waves'
    waves_dir.mkdir(parents=True, exist_ok=True)  # Ensure waves directory exists
    
    # Paths for the current dump.vcd and the destination dump.vcd
    src_vcd = test_dir / compute_unit_name / 'dump.vcd'
    dest_vcd = waves_dir / 'dump.vcd'
    
    # Move the current dump.vcd to the waves folder as "dump.vcd"
    shutil.move(src_vcd, dest_vcd)
    
    # Generate a unique filename based on the current timestamp and module
    timestamped_filename = datetime.now().strftime('%y%m%d_%H%M%S_') + module_under_test + '.vcd'
    timestamped_vcd = waves_dir / timestamped_filename
    
    # Copy the dump.vcd to create a timestamped version
    shutil.copy(dest_vcd, timestamped_vcd)
    
    # Log the timestamped file name for record keeping
    record_file = waves_dir / 'record.txt'
    with record_file.open('a') as record:
        record.write(f'{timestamped_filename}\n')  # Append the timestamped file name to the record
    
    print(f'Waveform {timestamped_filename} saved and recorded.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Cocotb Verilator runner')
    parser.add_argument('-n', type=str, required=True, help='Name of module being tested')
    parser.add_argument('-t', type=int, required=True, help='Trace waveform')
    args = parser.parse_args()
    module_under_test = args.n
    enable_trace = bool(args.t)

    # Get the current directory
    current_dir = Path(__file__).parent     # ./hardware/tb
    project_dir = current_dir.parent        # ./hardware
    test_dir = current_dir / 'test'
    sim_build_dir = current_dir / 'sim_build'

    # Remove previous sim_build.* and dump.vcd
    dump_vcd = Path(test_dir / compute_unit_name / 'dump.vcd')
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

    module_params = {}  # Add module parameters here
    
    single_test(
        test_id=1,
        dependencies=[compute_unit_name],
        top_module=f'{module_under_test}',
        test_module=f'{module_under_test}_tb',
        module_params=module_params,
        module_path=project_dir / 'rtl' / compute_unit_name / f'{module_under_test}.sv',
        component_path=project_dir / 'rtl' / compute_unit_name,
        sim_build_dir=sim_build_dir,
        test_files_dir=test_dir / compute_unit_name,
        enable_trace=enable_trace,
    )
    
    if enable_trace:
        move_file(test_dir, module_under_test)
