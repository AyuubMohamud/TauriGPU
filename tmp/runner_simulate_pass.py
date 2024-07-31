from os import getenv
from pathlib import Path
from cocotb.runner import get_runner
from typing import Any

def simulate_pass(
    project_dir: Path,
    module_params: dict[str, Any] = {},
    extra_build_args: list[str] = [],
    trace: bool = False,
):
    rtl_dir = project_dir / "rtl"
    sim_dir = project_dir / "sim" / "sim_build"

    fp_dir = rtl_dir / "core" / "fp"
    verilog_sources = list(fp_dir.glob("*.sv"))

    SIM = getenv("SIM", "verilator")

    top_module = "fp_mul"
    test_module = "fpu_tb"

    runner = get_runner(SIM)
    runner.build(
        verilog_sources=verilog_sources,
        includes=[rtl_dir],
        hdl_toplevel=top_module,
        build_args=[
            # Verilator linter is overly strict.
            # Too many errors
            # These errors are in later versions of verilator
            "-Wno-GENUNNAMED",
            "-Wno-WIDTHEXPAND",
            "-Wno-WIDTHTRUNC",
            # Simulation Optimisation
            "-Wno-UNOPTFLAT",
            # Signal trace in dump.fst
            *(["--trace-fst", "--trace-structs", "--trace"] if trace else []),
            "-prof-c",
            "--stats",
            "--assert",
            "-O2",
            "-build-jobs",
            "8",
            "-Wno-fatal",
            "-Wno-lint",
            "-Wno-style",
        ],
        parameters=module_params,
        build_dir=sim_dir,
    )
    runner.test(
        hdl_toplevel=top_module,
        hdl_toplevel_lang="verilog",
        test_module=test_module,
        results_xml="results.xml",
    )

# Sample usage:
if __name__ == "__main__":
    project_dir = Path(__file__).parent.parent
    module_params = {} # Add module parameters here
    simulate_pass(
        project_dir=project_dir,
        module_params=module_params,
        extra_build_args=[],
        trace=True # Enable trace to generate waveforms
    )