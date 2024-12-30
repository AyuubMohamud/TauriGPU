# Testbench Usage Guide

### Running the testbench

Dependencies:
```
cocotb 1.9.X
Verilator 5.X
```

Simply run: `python runner.py -t <0 or 1> -n <module_under_test>`.
Or alternatively, run the bash script `run.sh` in the `tb` folder.

`runner.py` automatically searches for the SV and testbench filepaths given the `<module_under_test>` argument. The testbench assumes all SV dependencies are within the same folder of the `module_under_test`. Ideally, the `rtl` code directory should mirror the `tb/test` directory layout.

... Explain the vcd generation ...

Some testbenches under `tb/test` are rather simple, such as the `fpu` testbenches, which were created in early development when there was less familiarity with cocotb. Later testbench iterations feature a reference model, usually labelled with `*_ref.py`, which is referred to by the testbench, `*_tb.py`.  