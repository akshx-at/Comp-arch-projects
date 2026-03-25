# Computer Architecture Projects

Collection of computer architecture work centered on a RISC-V out-of-order processor and supporting analysis material from UIUC coursework.

## Overview

This repository captures the implementation and documentation for an advanced processor design project, along with supporting benchmark analysis and final report material. The core deliverable is a SystemVerilog out-of-order RISC-V processor with simulation, synthesis, and verification infrastructure organized under a dedicated project directory.

## Main Project

### Out-of-Order RISC-V Processor

The primary project lives in `out-of-order-RISC-V_processor/` and contains the HDL, verification environment, synthesis collateral, and documentation for the processor design.

Highlights:

- RV32I/M-oriented processor design work in SystemVerilog
- Out-of-order execution concepts and advanced microarchitectural features
- Dedicated folders for simulation, synthesis, test programs, and package definitions
- Supporting design writeup and datapath diagram at the repository root

## Repository Layout

```text
Comp-arch-projects/
├── out-of-order-RISC-V_processor/
│   ├── bin/       # Scripts and helper tooling
│   ├── docs/      # Project documentation and design notes
│   ├── hdl/       # Hardware implementation
│   ├── hvl/       # Verification/testbench code
│   ├── lint/      # Lint configuration and outputs
│   ├── pkg/       # Shared package/type definitions
│   ├── sim/       # Simulation flow
│   ├── sram/      # Memory macros/models
│   ├── synth/     # Synthesis flow
│   └── testcode/  # Benchmarks and test programs
├── benchmark_analysis.py
├── ECE411_final_report.pdf
├── mp_ooo_datapath.png
└── README.md
```

## Supporting Materials

- `ECE411_final_report.pdf`: final report summarizing the design approach and outcomes
- `mp_ooo_datapath.png`: high-level datapath visualization
- `benchmark_analysis.py`: utility script for analyzing benchmark behavior and performance data

## Tooling

The exact toolchain depends on the subproject flow, but this repository is intended to be used with a typical hardware design stack:

- SystemVerilog simulator
- synthesis tooling
- Python 3 for analysis scripts
- RISC-V test binaries and benchmark inputs

Refer to the documentation inside `out-of-order-RISC-V_processor/docs/` and any Makefiles in the subdirectories for environment-specific commands.

## Why This Repository Matters

This project emphasizes hardware/software performance thinking rather than only functional correctness. It demonstrates experience with processor pipelines, verification, benchmarking, and the documentation needed to explain a non-trivial architecture project clearly.
