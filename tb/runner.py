from pathlib import Path
from single_test import single_test

if __name__ == "__main__":
    project_dir = Path(__file__).parent.parent
    tb_dir = Path(__file__).parent
    test_dir = tb_dir / "test"
    sim_build_dir = tb_dir / "sim_build"
    module_params = {}  # Add module parameters here
    
    # Ensure sim_build_dir exists
    sim_build_dir.mkdir(parents=True, exist_ok=True)
    
    # Example usage of single_test function
    result = single_test(
        i=1,
        deps=["fp"],
        module="fp_mul",
        test_module="fpu_mul_tb",
        module_params={},
        module_path=project_dir / "rtl" / "core" / "fp" / "fp_mul.sv",
        comp_path=project_dir / "rtl" / "core",
        test_work_dir=sim_build_dir,
        test_dir=test_dir,
        trace=True
    )
    print(f"Test result: {result}")