# Single-Cycle MIPS CPU

In this project we were tasked with designing the Single-Cycle 
(non-pipelined) version of the MIPS processor that supports the
following subset, i.e., 16 instructions of MIPS ISA:

  - 9 Arithmetic/Logical instructions: `add`, `sub`, `and`, `or`, `nor`, `slt`, `addi`, `ori`, `lui`
  - 2 Memory reference: `lw`, `sw`
  - 5 Control transfer: `beq`, `bne`, `j`, `jal`, `jr`

The processor has the following interface:

  - Inputs
    - Clock (`clk` -> 1 bit)
    - Asynchronous reset for processor initialization and for mimicking program load (`rst` -> 1 bit)

Here is the microarchitecture I drew up

[./arch.png](Single-Cycle (non-pipelined) MIPS microarchitecture supporting 16 instructions)

Repository structure

  - `design_sources` - actual VHDL code for the MIPS CPU
  - `references` - VHDL documentation and architecture references
  - `results` - expected clock graph for MIPS fibonacci for our CPU
  - `simulation_sources` - VHDL simulation specifics
  - `test_program` - MIPS fibonacci (recursive/non-rec) to test our CPU
  - `vivado_project` - Xilinx Vivado repository for project management

This project was fun. I don't really want to touch VHDL in the near future.
