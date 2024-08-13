from pathlib import Path
from single_test import single_test
import shutil
import glob

if __name__ == "__main__":
    # Get the current directory (same as runner.py)
    current_dir = Path(__file__).parent

    # Remove all previous sim_build.* files/directories
    for item in current_dir.glob('sim_build.*'):
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)
    
    print("Removed all previous sim_build.* files/directories.")

    project_dir = current_dir.parent
    tb_dir = current_dir
    test_dir = tb_dir / "test"
    sim_build_dir = tb_dir / "sim_build"
    module_params = {}  # Add module parameters here
    
    # Ensure sim_build_dir exists
    sim_build_dir.mkdir(parents=True, exist_ok=True)
    
    ### Calling single test function ###

    result = single_test(
        i=1,
        deps=["fp"],
        module="fpu",
        test_module="fpu_sub_tb",
        module_params={},
        module_path=project_dir / "rtl" / "core" / "fp" / "fpu.sv",
        comp_path=project_dir / "rtl" / "core",
        test_work_dir=sim_build_dir,
        test_dir=test_dir / "core" / "fpu",
        trace=True
    )

    print(f"Test result: {result}")