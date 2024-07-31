from pathlib import Path

# Define the project structure
PROJECT_ROOT = Path(__file__).parent.parent
RTL_ROOT = PROJECT_ROOT / "rtl" / "core"

# Test configuration
TEST_CONFIG = {
    "fpu_mul_tb": {
        "module": "fp_mul",
        "module_path": RTL_ROOT / "fp" / "fp_mul.sv",
        "deps": ["fp"],
    },
    # Add more test configurations here
    # "another_test_module": {
    #     "module": "another_module",
    #     "module_path": RTL_ROOT / "path" / "to" / "another_module.sv",
    #     "deps": ["dep1", "dep2"],
    # },
}

# Function to get test configuration
def get_test_config(test_module):
    config = TEST_CONFIG.get(test_module)
    if not config:
        raise ValueError(f"Test configuration not found for {test_module}")
    return config