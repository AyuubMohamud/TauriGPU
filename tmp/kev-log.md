# Logbook

### Timelog
July 3, 2024
[OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2024-07-03)

July 9, 2024
4 Shader Execution Units (SEUs) - each SEU has 4 ALUs, 4 FPUs, 1 SFU, 1 TMU, 1 instruction cache, 1 control unit

### Notes

Goal 1: Run (bare-metal) a visualisation of a spinning 3D cube

Goal 2: Run Doom (classic) on Linux

---

Tiny-GPU + rasteriser + texture unit + fp16 + 32-bit integers

ISA: Cutdown RISC-V, need (add, sub, mul, reciprocal sqrt, sin, cos)
Memory and SFU - 4 calls

ALU and FPU - can just read as long as there are no hazards
There are two register files to prevent conflict between cycle running for ALU vs FPU

---

--> Vertex shader
- Object to screen space

--> Rasterisation stage 
- Vertex to fragment, aka pixels
- Barycentric coordinates computed to interpolate vertex attributes

--> Fragment shader
- Runs per fragment (pixel)
- Interpolated values

--> Testing (alpha -> stencil -> depth)

