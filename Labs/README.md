# ECE310 Laboratory Assignments

This directory contains the weekly laboratory assignments from ECE 310 (Design of Complex Digital Systems) at NC State University, focusing on fundamental digital logic design and Verilog programming concepts.

## 🗂️ Lab Structure

```
Labs/
├── Lab 1/
│   ├── ECE 310 - Lab 1.pdf     # Lab assignment instructions
│   └── lab1.v                  # Basic Verilog introduction
├── Lab 2/
│   ├── ECE 310 - Lab 2.pdf     # Lab assignment instructions
│   ├── full_adder_struct.v     # Full adder and 4-bit RCA implementation
│   └── Lab 2 Report.pdf        # Lab report and analysis
├── Lab 3/
│   ├── ECE 310 - Lab 3.pdf     # Lab assignment instructions
│   ├── ksa_4bit_df.v           # 4-bit Kogge-Stone adder implementation
│   ├── ksa_4bit_tb.v           # Kogge-Stone adder testbench
│   └── Lab 3 Report.pdf        # Lab report and analysis
└── Labs 4-8/                   # Future assignments (in progress)
```

## 🔬 Laboratory Assignments

### Lab 1: Introduction to Verilog
**File**: `Lab 1/lab1.v`

A basic introduction to Verilog programming focusing on:
- Verilog syntax and module structure
- `$display` system task usage
- Basic simulation setup

**Key Features**:
- Simple module demonstrating console output
- Introduction to Verilog testbench concepts

### Lab 2: Digital Logic Design - Full Adder
**File**: `Lab 2/full_adder_struct.v`

Implementation of combinational logic circuits using structural Verilog:
- **Full Adder**: Gate-level implementation using XOR, AND, and OR gates
- **4-bit Ripple Carry Adder (RCA)**: Cascaded full adders for multi-bit addition
- **Comprehensive Testbench**: Thorough testing of edge cases and carry propagation

**Key Features**:
- Structural modeling with primitive gates
- Wire declarations and signal propagation
- Multi-bit arithmetic operations
- Systematic testbench design with various test cases:
  - All zeros baseline test
  - Maximum values overflow test
  - Carry propagation verification
  - Mixed input patterns
  - MSB addition testing

**Technical Specifications**:
- 4-bit input operands (A, B)
- 4-bit sum output (S)
- Carry-out flag (Cout)
- Gate-level implementation for educational clarity

### Lab 3: Advanced Arithmetic - Kogge-Stone Adder
**Files**: `Lab 3/ksa_4bit_df.v`, `Lab 3/ksa_4bit_tb.v`

Implementation of a high-performance parallel prefix adder using the Kogge-Stone algorithm:
- **4-bit Kogge-Stone Adder**: Advanced parallel adder with logarithmic depth
- **Multi-stage Architecture**: Three-stage pipeline for optimal carry propagation
- **Performance Optimization**: Reduced critical path delay compared to ripple carry adders

**Key Features**:
- **Parallel Prefix Computation**: Generate and propagate signals computed in parallel
- **Tree Structure**: Logarithmic depth architecture (3 stages for 4-bit)
- **Optimized Carry Logic**: Faster carry generation using G and P functions
- **Comprehensive Testing**: Systematic testbench covering:
  - Baseline zero cases
  - Simple non-carry operations
  - Carry generation and propagation
  - Overflow conditions
  - Maximum value testing
  - Random mid-range values

**Technical Specifications**:
- Algorithm: Kogge-Stone parallel prefix
- Bit width: 4-bit operands
- Stages: 3 (logarithmic complexity)
- Propagation delay: O(log n) vs O(n) for ripple carry
- Area complexity: Higher gate count for improved speed

**Architecture Overview**:
- **Stage 0**: Initial generate (G) and propagate (P) computation
- **Stage 1**: First level of prefix computation
- **Stage 2**: Second level spanning longer distances
- **Stage 3**: Final carry computation and sum generation

### Labs 4-8: [In Progress]
Future laboratory assignments covering advanced digital design topics including:
- Sequential logic circuits
- State machines and control units
- Memory systems and cache design
- Processor architecture components
- Advanced optimization techniques

**Progress**: 3 of 8 labs completed (37.5%)


## 📋 Lab Reports

Lab reports compiled in LaTeX (where available) provide detailed analysis including:
- Circuit design methodology
- Simulation results and verification
- Timing analysis and performance evaluation
- Design trade-offs and optimization considerations