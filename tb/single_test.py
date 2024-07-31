from os import getenv, environ, path
from pathlib import Path
from cocotb.runner import get_runner
from typing import Any
import xml.etree.ElementTree as ET
import sys
import shutil
from time import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from copy import deepcopy
import inspect
import re

def get_results(results_file: Path):
    if not results_file.exists():
        print(f"Results file not found: {results_file}")
        return 0, 1
    tree = ET.parse(results_file)
    root = tree.getroot()
    num_tests = int(root.attrib['tests'])
    fail = int(root.attrib['failures'])
    return num_tests, fail

def single_test(
    i: int,  # id
    deps: list[str],
    module: str,
    test_module: str,
    module_params: dict,
    module_path: Path,
    comp_path: Path,
    test_work_dir: Path,
    test_dir: Path,
    extra_build_args: list[str] = [],
    seed: int = None,
    trace: bool = False,
    skip_build: bool = False,
):
    print("# ---------------------------------------")
    print(f"# Test {i}")
    print("# ---------------------------------------")
    print(f"# Parameters:")
    print(f"# - {'Test Index'}: {i}")
    for k, v in module_params.items():
        print(f"# - {k}: {v}")
    print("# ---------------------------------------")
    
    # Gather all Verilog files in the module directory and its subdirectories
    verilog_sources = [str(p) for p in Path(module_path).parent.glob('**/*.sv')]
    print(f"Verilog sources: {verilog_sources}")
    
    # Add the test directory to Python's sys.path
    sys.path.append(str(test_dir))
    print(f"Added to Python path: {test_dir}")
    
    # Set environment variables to control file output locations
    environ['PYTHONPYCACHEPREFIX'] = str(test_work_dir / '__pycache__')
    environ['GMON_OUT_PREFIX'] = str(test_work_dir)
    
    runner = get_runner(getenv("SIM", "verilator"))
    if not skip_build:
        try:
            runner.build(
                verilog_sources=verilog_sources,
                includes=[str(comp_path.joinpath(f"{d}/rtl/")) for d in deps] + [str(Path(module_path).parent)],
                hdl_toplevel=module,
                build_args=[
                    "-Wno-GENUNNAMED",
                    "-Wno-WIDTHEXPAND",
                    "-Wno-WIDTHTRUNC",
                    "-Wno-UNOPTFLAT",
                    "-prof-c",
                    "--assert",
                    "--stats",
                    *(["--trace-fst", "--trace-structs"] if trace else []),
                    "-O2",
                    "-build-jobs",
                    "8",
                    "-Wno-fatal",
                    "-Wno-lint",
                    "-Wno-style",
                    *extra_build_args,
                ],
                parameters=module_params,
                build_dir=test_work_dir,
            )
        except Exception as e:
            print(f"Error occurred during build: {e}")
            return {
                "num_tests": 0,
                "failed_tests": 1,
                "params": module_params,
                "error": str(e)
            }
    
    try:
        runner.test(
            hdl_toplevel=module,
            hdl_toplevel_lang="verilog",
            test_module=test_module,
            seed=seed,
            results_xml=str(test_work_dir / "results.xml"),
            build_dir=test_work_dir,
            test_dir=str(test_dir),
        )
        num_tests, fail = get_results(test_work_dir / "results.xml")
        
        # Move gmon.out if it exists in test_dir
        gmon_src = test_dir / "gmon.out"
        if gmon_src.exists():
            shutil.move(str(gmon_src), str(test_work_dir / "gmon.out"))
        
    except Exception as e:
        print(f"Error occurred while running Verilator simulation: {e}")
        num_tests, fail = 0, 1
    
    return {
        "num_tests": num_tests,
        "failed_tests": fail,
        "params": module_params,
    }