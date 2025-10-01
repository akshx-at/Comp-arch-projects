# Computer Architecture Projects

A collection of advanced computer architecture projects from ECE 411 (Computer Organization & Design) at the University of Illinois Urbana-Champaign.

## 📋 Table of Contents
- [Overview](#overview)
- [Projects](#projects)
  - [Out-of-Order Processor (mp_ooo)](#out-of-order-processor-mp_ooo)
  - [TLB Flushers](#tlb-flushers)
- [Benchmark Analysis Tools](#benchmark-analysis-tools)
- [Documentation](#documentation)
- [Getting Started](#getting-started)

## Overview

This repository contains implementations of advanced processor architectures and performance analysis tools developed as part of the ECE 411 coursework. The main focus is on designing and optimizing an out-of-order (OoO) RISC-V processor with various advanced microarchitectural features.

## Projects

### Out-of-Order Processor (mp_ooo)

A fully functional out-of-order microprocessor implementing the RV32IM instruction set using an Explicit Register Renaming (ERR) architecture.

#### 🎯 Key Features

**Core Architecture:**
- **Out-of-Order Execution**: Implements Explicit Register Renaming with physical register file
- **RISC-V ISA Support**: Full RV32IM instruction set (excluding FENCE*, ECALL, EBREAK, CSRR)
- **Advanced Pipeline Stages**: Fetch → Decode → Rename/Dispatch → Issue → Execute → Writeback → Commit
- **Precise State**: Maintained through Re-Order Buffer (ROB) for accurate exception handling

**Advanced Features Implemented:**
- **Branch Prediction**: 
  - Tournament predictor combining multiple prediction schemes
  - GShare predictor for global history-based prediction
  - Two-level predictor (Local History Table & Pattern History Table)
  - Return Address Stack (RAS) for function call optimization
  - Branch Target Buffer (BTB) integration
  
- **Memory Subsystem**:
  - Split Load/Store Queue (LSQ) for out-of-order memory operations
  - Post-commit store buffer (PCSB) for improved write throughput
  - Non-blocking cache support
  - Cache hierarchy with separate I-cache and D-cache
  
- **Prefetching**:
  - Instruction prefetcher for improved fetch bandwidth
  - Next-line prefetching capabilities
  
- **Performance Optimizations**:
  - Pipelined multiplication and division using Synopsys DesignWare IP
  - Multiple reservation stations for parallel execution
  - Common Data Bus (CDB) for result broadcasting
  - Age-ordered issue scheduling

#### 📊 Performance Metrics

- **Clock Period**: 2250 ps (444 MHz)
- **Target IPC**: Optimized for CoreMark and benchmark suite
- **Area**: Synthesizable on ASIC process with area constraints

#### 🛠️ Technical Implementation

**Hardware Description:**
- Language: SystemVerilog
- Verification: VCS/Verilator simulation with RVFI reference model
- Synthesis: Synopsys Design Compiler with timing constraints
- Memory Model: Banked burst DRAM with out-of-order response support

**Key Components** (in `hdl/`):
- `cpu.sv` - Top-level CPU module
- `fetch.sv` - Instruction fetch stage
- `decode.sv` - Instruction decoder
- `rename_dispatch.sv` - Register renaming and dispatch logic
- `rs_*.sv` - Reservation stations (add, mul, div, load/store)
- `ROB.sv` - Reorder Buffer
- `RAT.sv` - Register Alias Table
- `RRF.sv` - Retirement Register File
- `physical_regfile.sv` - Merged physical register file
- `lsq.sv` - Load/Store Queue
- `tournament_predictor.sv` - Hybrid branch predictor
- `cache.sv` - Cache implementation

**Testbenches & Verification:**
- Random instruction generator
- RVFI monitor for Spike reference comparison
- Functional coverage for instruction types
- CoreMark benchmark suite

#### 📈 Design Competition Results

The processor was evaluated on a competitive leaderboard against peer implementations:
- Correctness: Validated against Spike ISA simulator
- Performance: Measured on multiple benchmark programs
- Metrics: IPC, execution cycles, cache performance

#### 🔧 Build & Simulation

```bash
cd mp_ooo

# Compile with VCS
make -C sim

# Run simulation with a test program
make -C sim run PROG=../testcode/coremark_im.elf

# Check IPC
./sim/get_ipc.sh

# Synthesize design
make -C synth

# Check timing
./synth/get_slack.sh
```

See [mp_ooo/README.md](mp_ooo/README.md) and [mp_ooo/docs/](mp_ooo/docs/) for detailed documentation.

### TLB Flushers

A team project focusing on Translation Lookaside Buffer (TLB) optimizations and memory management unit (MMU) design.

Location: `fa24_ece411_TLB_Flushers/`

## Benchmark Analysis Tools

### benchmark_analysis.py

A comprehensive Python script for analyzing processor performance from Spike simulation logs.

**Features:**
- **Branch Statistics**: Calculates branch taken/not-taken ratios
- **Instruction Mix Analysis**: Breaks down percentage of load, store, branch, and arithmetic instructions
- **Dependency Analysis**: Measures average distance between dependent load/store operations
- **Memory Access Patterns**: Tracks RAW, WAR, and WAW dependencies

**Usage:**
```python
python benchmark_analysis.py
```

The script analyzes Spike log files to identify performance bottlenecks and optimization opportunities:
- Branch prediction accuracy requirements
- Memory dependency patterns
- Instruction-level parallelism opportunities
- Cache behavior implications

## Documentation

### Design Documentation
- **Datapath Diagram** (`mp_ooo_datapath.png`): Visual representation of the OoO processor architecture
- **Final Report** (`ECE411_final_report.pdf`): Comprehensive analysis and results

### Technical Guides (in `mp_ooo/docs/`)
- [GUIDE.md](mp_ooo/docs/GUIDE.md) - Implementation tips and resources
- [WHAT_IS_AN_OOO.md](mp_ooo/docs/WHAT_IS_AN_OOO.md) - Out-of-order execution fundamentals
- [ADVANCED_FEATURES.md](mp_ooo/docs/ADVANCED_FEATURES.md) - Advanced feature catalog
- [COMPETITION.md](mp_ooo/docs/COMPETITION.md) - Competition and grading details
- [TEST_CASES.md](mp_ooo/docs/TEST_CASES.md) - Test case overview
- [VERILATOR.md](mp_ooo/docs/VERILATOR.md) - Verilator toolflow guide

## Getting Started

### Prerequisites
- Synopsys VCS (for simulation)
- Synopsys Design Compiler (for synthesis)
- RISC-V GNU Toolchain (for compiling test programs)
- Python 3.x (for analysis scripts)
- Spike RISC-V ISA Simulator (for reference)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Comp-arch-projects
   ```

2. **Navigate to the OoO processor**
   ```bash
   cd mp_ooo
   ```

3. **Run a simple test**
   ```bash
   make -C sim run PROG=../testcode/cp3_example.s
   ```

4. **Analyze performance**
   ```bash
   cd ..
   python benchmark_analysis.py
   ```

### Repository Structure

```
Comp-arch-projects/
├── mp_ooo/                          # Main out-of-order processor project
│   ├── hdl/                         # SystemVerilog source files
│   ├── hvl/                         # Verification testbenches
│   ├── sim/                         # Simulation scripts and Makefiles
│   ├── synth/                       # Synthesis scripts
│   ├── testcode/                    # Test programs and benchmarks
│   ├── docs/                        # Documentation
│   └── pkg/                         # Type definitions
├── fa24_ece411_TLB_Flushers/       # TLB optimization project
├── benchmark_analysis.py            # Performance analysis tool
├── mp_ooo_datapath.png             # Architecture diagram
├── ECE411_final_report.pdf         # Final project report
└── README.md                        # This file
```

## Key Achievements

- ✅ Implemented full RV32IM instruction set in hardware
- ✅ Designed and verified an out-of-order execution engine
- ✅ Integrated multiple advanced microarchitectural features (20+ points)
- ✅ Achieved competitive performance on industry-standard benchmarks
- ✅ Successfully synthesized design meeting timing constraints at 444 MHz
- ✅ Developed comprehensive verification infrastructure with RVFI
---

*For detailed information about specific components, refer to the documentation in each project directory.*

