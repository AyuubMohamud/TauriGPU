import sys, shutil
from pathlib import Path
from os import getenv, environ

from cocotb.runner import get_runner

from mods.logging_mods import *


def single_test(
    test_id: int,               # Test identifier
    dependencies: list[str],    # List of dependencies
    top_module: str,            # Top module name
    test_module: str,           # Cocotb test module name
    module_params: dict,        # Parameters for the module
    module_path: Path,          # Path to the module file
    component_path: Path,       # Path to the component files
    sim_build_dir: Path,        # Working directory for the test
    test_files_dir: Path,       # Directory with the python testbench files
    extra_build_args: list[str] = [],  # Extra build arguments for the build process
    seed: int = None,           # Random seed for the test
    enable_trace: bool = False, # Enable waveform trace
    skip_build: bool = False,   # Skip the build process if True
):
    print(f"# ---------------------------------------")
    print(f"# Test {test_id}")
    print(f"# ---------------------------------------")
    print(f"# Parameters:")
    print(f"# - {'Test Index'}: {test_id}")
    for param_name, param_value in module_params.items():
        print(f"# - {param_name}: {param_value}")
    print("# ---------------------------------------")
    
    # Gather all Verilog files in the module directory and its subdirectories
    verilog_sources = [str(p) for p in Path(module_path).parent.glob('**/*.sv')]
    print(f"Verilog sources:")
    print_list(verilog_sources)
    
    # Add the test files' directory to Python's sys.path
    sys.path.append(str(test_files_dir))
    print(f"Added to Python path: {test_files_dir}")
    
    # Set environment variables to control file output locations
    environ['PYTHONPYCACHEPREFIX'] = str(sim_build_dir / '__pycache__')
    environ['GMON_OUT_PREFIX'] = str(sim_build_dir)
    
    # Initialize the Verilator simulation runner
    runner = get_runner(getenv("SIM", "verilator"))
    # Build the simulation unless skipping the build
    if not skip_build:
        try:
            runner.build(
                verilog_sources=verilog_sources,
                includes=[str(component_path.joinpath(f"{d}/rtl/")) for d in dependencies]
                          + [str(Path(module_path).parent)] + ['/home/xl562/3dgs/3DGS/hardware/rtl/vru'],
                hdl_toplevel=top_module,
                build_args=[
                    "-Wno-GENUNNAMED",
                    "-Wno-WIDTHEXPAND",
                    "-Wno-WIDTHTRUNC",
                    "-Wno-UNOPTFLAT",
                    "-prof-c",
                    "--assert",
                    "--stats",
                    "-O2",
                    "-build-jobs",
                    "8",
                    "-Wno-fatal",
                    "-Wno-lint",
                    "-Wno-style",
                    *extra_build_args,
                ],
                parameters=module_params,
                build_dir=sim_build_dir,
                waves=enable_trace
            )
        except Exception as build_error:
            print(f"Error occurred during build: {build_error}")
            return {
                "num_tests": 0,
                "failed_tests": 1,
                "params": module_params,
                "error": str(build_error)
            }

    # Run the test
    try:
        runner.test(
            hdl_toplevel=top_module,
            hdl_toplevel_lang="verilog",
            test_module=test_module,
            seed=seed,
            results_xml=str(sim_build_dir / "results.xml"),
            build_dir=sim_build_dir,
            test_dir=str(test_files_dir),
            waves=enable_trace
        )
        
        # Move profiling output if it exists
        gmon_src = test_files_dir / "gmon.out"
        if gmon_src.exists():
            shutil.move(str(gmon_src), str(sim_build_dir / "gmon.out"))
        
    except Exception as build_error:
        print(f"Error occurred while running Verilator simulation: {build_error}")