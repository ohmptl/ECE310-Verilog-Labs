# ECE310 Verilog Labs

A comprehensive collection of Verilog laboratory assignments from ECE 310 (Computer Organization) at North Carolina State University. This repository showcases fundamental digital logic design concepts and hardware description language (HDL) programming skills.

## 📚 Course Information

- **Course**: ECE 310 - Computer Organization
- **Institution**: North Carolina State University (NCSU)
- **Student**: Ohm Patel
- **Academic Year**: 2025

## 🗂️ Repository Structure

```
ECE310-Verilog-Labs/
├── README.md
├── Lab 1/
│   ├── ECE 310 - Lab 1.pdf     # Lab assignment instructions
│   └── lab1.v                  # Basic Verilog introduction
├── Lab 2/
│   ├── ECE 310 - Lab 2.pdf     # Lab assignment instructions
│   ├── full_adder_struct.v     # Full adder and 4-bit RCA implementation
│   └── Lab 2 Report.pdf        # Lab report and analysis
└── Lab 3/
    └── ECE 310 - Lab 3.pdf     # Lab assignment instructions
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

### Lab 3: [In Progress]
**File**: `Lab 3/` (Implementation pending)


## 📈 Learning Outcomes

Through these laboratory exercises, the following concepts are explored:

- **Digital Logic Design**: Understanding of combinational circuits
- **Hardware Description Languages**: Proficiency in Verilog syntax and semantics
- **Structural Modeling**: Gate-level circuit design and implementation
- **Testbench Development**: Creating comprehensive test scenarios
- **Timing Analysis**: Understanding propagation delays and signal timing
- **Multi-bit Arithmetic**: Implementation of binary addition circuits

## 📋 Lab Reports

Lab reports complied in LaTeX (where available) provide detailed analysis including:
- Circuit design methodology
- Simulation results and verification
- Timing analysis and performance evaluation
- Design trade-offs and optimization considerations

## 📄 License

This repository is intended for educational use. Please respect academic integrity policies when referencing this work.

---

*This repository demonstrates practical application of digital logic design principles through hands-on Verilog programming exercises in computer organization.* 
