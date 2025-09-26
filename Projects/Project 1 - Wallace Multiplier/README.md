# 8×8 Wallace Tree Multiplier
This repository contains the implementation and testbench for an 8×8 unsigned Wallace multiplier in Verilog at the gate/structural level.

## 👨‍💻 Skills & Tools Demonstrated

- Digital design with structural Verilog
- RTL development for combinational circuits
- Testbench creation and verification
- Simulation and debugging (Vivado/ModelSim)
- Formal documentation (LaTeX)

## ⚡ Key Features

- **Fully structural implementation**: Gate-level Verilog design using only basic logic gates
- **Modular architecture**: Separate modules for AND gates, half adders, full adders, and ripple carry adder
- **Comprehensive testing**: Exhaustive testbench with detailed waveform analysis
- **Optimized design**: Wallace tree structure for improved multiplication speed
- **Well-documented**: Complete design reports with diagrams and analysis

## 🎯 Implementation Details

The Wallace multiplier reduces the number of partial products through a tree structure of carry-save adders, providing faster multiplication compared to traditional array multipliers. This implementation demonstrates:

- Structural Verilog coding practices
- Digital circuit optimization techniques
- Comprehensive verification methodology
- Professional documentation standards

## 🏗️ Repo Structure

```
Project 1 - Wallace Multiplier/
├── README.md                               # Project-specific documentation
├── project1.v                              # Main Wallace multiplier implementation
├── rca.v                                   # Ripple carry adder component
├── wallace_exhaustive_tb.v                 # Comprehensive testbench
├── Project_Design.pdf                      # Design documentation
└── Wallace Multiplier Final Report.pdf     # Complete project report
```

## 📝 Report & Documentation

Comprehensive documentation available in `/docs`:
- `Project_Design.pdf` - Design specifications and methodology
- `Wallace Multiplier Final Report.pdf` - Complete analysis including:
  - Block and gate-level diagrams
  - Gate count analysis
  - Simulation results and waveforms
  - Performance evaluation
  - Design reflections and conclusions

## 🧠 Getting Started

This project demonstrates advanced digital design concepts and serves as an excellent reference for:
- Students learning about multiplier architectures
- Engineers implementing high-speed arithmetic circuits
- Researchers studying combinational circuit optimization

