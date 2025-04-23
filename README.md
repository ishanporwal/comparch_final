# 32-bit RISC-V Processor (Miniproject 4)

This project implements a multi-cycle, unpipelined 32-bit RISC-V processor using SystemVerilog and the OSS CAD Suite. It was developed as part of the Computer Architecture course at Olin College of Engineering (Spring 2025) by Ahan Trivedi, Ishan Porwal, Nividh Singh, and Ertug Umsur.

## Overview

- **Instruction Set:** RV32I base integer instruction set (excluding system and atomic instructions)
- **Architecture:** Multi-cycle, unpipelined processor with Von Neumann memory
- **Target Platform:** iceBlinkPico FPGA board
- **Verification:** Functional simulation using icarus verilog and GTKWave and execution of RISC-V programs

## Repository Structure

```
├── alu.sv                  # ALU logic for arithmetic and logic operations
├── branch_logic.sv         # Branch decision logic
├── control_unit.sv         # FSM control logic for the datapath
├── immediate_generator.sv  # Sign-extension and immediate decoding
├── instruction_decode.sv   # Instruction decoding and operand forwarding
├── instruction_register.sv # Holds the current instruction
├── memory.sv               # Unified instruction/data memory
├── program_counter.sv      # PC logic with jump and branch support
├── register_file.sv        # 32x32-bit register file
├── testbench.sv            # Top-level testbench to simulate processor behavior
├── top.sv                  # Processor top-level module integrating all components
├── datapath_test.txt       # Simple instruction file to validate data path flow
├── test_1.txt              # First set of broad instructions
├── test_2.txt              # Second set of broad instructions
├── test_3.txt              # Instructions involving storing and loading with memory
└── README.md               # Project overiview
```

## How to Simulate

1. **Install OSS CAD Suite** (https://github.com/YosysHQ/oss-cad-suite-build)
2. **Run simulation:**

```bash
iverilog -g2012 -o final testbench.sv
vvp final
```

3. **Optional waveform generation:**

```bash
gtkwave processor.vcd
```

## Authors

- Ahan Trivedi
- Ishan Porwal
- Nividh Singh
- Ertug Umsur

## License

This project is intended for educational purposes and is released without a specific license.
