# Kevin's Logbook

### Tasks at hand
- Pipeline add stage
- Finish decode (+ fpu hazard unit)
- Look at rastericer

### Timelog
July 3, 2024
[OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2024-07-03)

July 9, 2024
4 Shader Execution Units (SEUs) - each SEU has 4 ALUs, 4 FPUs, 1 SFU, 1 TMU, 1 instruction cache, 1 control unit

### Notes

Read Raspberry Pi's GPU driver documentation

Goal 1: Run (bare-metal) a visualisation of a spinning 3D cube
Goal 2: Run Doom (classic) on Linux

Tiny-GPU + rasteriser + texture unit + fp16 + 32-bit integers

ISA: Cutdown RISC-V, need (add, sub, mul, reciprocal sqrt, sin, cos)


Memory and SFU - 4 calls
ALU and FPU - can just read as long as there are no hazards

