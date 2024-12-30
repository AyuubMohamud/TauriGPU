# TauriGPU

### Introduction

This repo includes the RTL design and testbench of our immediate-mode GPU, Tauri. The goal of the GPU is to run Doom (1993), running the GPU on a Vivado 7 series / Zynq-7000 SoC FPGA, and supporting the OpenGL ES2 standard. The repo will in the near future feature a LLVM backend for Tauri's ISA (enable compilation of GLSL code through SPIR-V to LLVM IR translation).

Tauri is currently under iteration v0.1, which goal is to run simple DRAM-preloaded rasterisation graphics. 

Tauri will enter iteration v0.2 in January 2025, with the expected full completion date being before the end of 2025. 

### Testbench

Tauri's testbench currently features a premature cocotb-based testbench which closely follows the principles of formal verification, though is not fully object-oriented. Feel free to copy and use it, though take care of the differences between repos and expected file paths given the automated testbench and dependency location search.


