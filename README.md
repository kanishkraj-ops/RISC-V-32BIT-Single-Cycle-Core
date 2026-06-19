# RISC-V 32-bit Single-Cycle Core
 
A from-scratch, structurally-written **32-bit single-cycle RISC-V (RV32I-style) processor core** built in Verilog HDL and verified entirely inside Xilinx Vivado.
 
Every instruction — fetch, decode, execute, memory access, and writeback — completes in **one clock cycle**. The datapath is built as discrete, hand-wired modules (no behavioral shortcuts for the core control path), which makes it a clear reference for understanding how a classic RISC datapath is assembled from first principles.
 
> 📌 **Status:** functional core verified in simulation (Vivado XSIM). Not yet synthesized/deployed to a physical FPGA board in this repo.
 
---
 
## Table of Contents
 
- [Overview](#overview)
- [Microarchitecture](#microarchitecture)
- [Module Breakdown](#module-breakdown)
- [Control Signal Matrix](#control-signal-matrix)
- [Repository Structure](#repository-structure)
- [Verification & Test Suite](#verification--test-suite)
- [Getting Started](#getting-started)
- [Sample Simulation Output](#sample-simulation-output)
- [Roadmap](#roadmap)
- [License](#license)
---
 
## Overview
 
This core implements a **single-cycle RV32I-inspired execution path**: every instruction enters Instruction Memory, is decoded combinationally, executed through the ALU, optionally touches Data Memory, and is written back to the register file — all within one rising clock edge to the next.
 
Currently supported instruction classes:
 
| Type | Instructions | Notes |
|---|---|---|
| R-Type | `add`, arithmetic/logical ops decoded via `funct3`/`funct7` | Register-register ALU ops |
| I-Type | `addi` and other immediate arithmetic ops | Immediate-register ALU ops |
| Load | `lw` | Word-aligned load from data memory |
| Store | `sw` | Word-aligned store to data memory |
 
The design deliberately separates **synchronous state** (Program Counter, Register File, Data Memory writes) from **pure combinational logic** (Control Unit, ALU Control, Immediate Generator, ALU), keeping the datapath easy to trace signal-by-signal.
 
---
 
## Microarchitecture
 
```
                         +-----------------------+
                         |   INSTRUCTION MEMORY   |
                         |  addr -> instr[31:0]   |
                         +-----------^------------+
                                     |
          +--------------------------+--------------------------+
          |                          |                          |
   +------+------+          +--------+--------+         +-------+-------+
   |  PROGRAM    |          |  CONTROL UNIT   |         |  REGISTER     |
   |  COUNTER    |          |  (opcode -> ctl)|         |  FILE (x0-x31)|
   +------+------+          +--------+--------+         +-------+-------+
          |                          |                          |
   +------+------+          +--------+--------+         +-------+-------+
   |  ADDER (+4) |          |  ALU CONTROL    |         |  IMMEDIATE    |
   |  pc + 4     |          |  (funct -> op)  |         |  GENERATOR    |
   +-------------+          +--------+--------+         +-------+-------+
                                     |                          |
                              +------+------+                  |
                              |  ALU SRC MUX|<-----------------+
                              +------+------+
                                     |
                              +------+------+
                              |     ALU     |---- Zero flag (branch logic)
                              +------+------+
                                     |
                              +------+------+
                              | DATA MEMORY |
                              |   (RAM)     |
                              +------+------+
                                     |
                              +------+------+
                              | WRITEBACK   |
                              |    MUX      |---> back to Register File
                              +-------------+
```
 
**Signal flow, in order:**
 
1. **Fetch** — `program_counter.v` holds the current address; `instruction_mem.v` returns the 32-bit instruction at that address asynchronously.
2. **Decode** — the instruction is split into `opcode`, `rs1`, `rs2`, `rd`, `funct3`, `funct7` fields. `control_unit.v` reads the opcode and asserts datapath control signals. `imm_gen.v` sign-extends the relevant immediate field. `register file` reads `rs1`/`rs2` in the same cycle.
3. **Execute** — `alu_control.v` combines `ALUop` with `funct3`/`funct7` to select the exact ALU operation. The ALU operand-B mux selects between the register value and the sign-extended immediate based on `ALUSrc`. `alu.v` computes the result and a `Zero` flag.
4. **Memory** — `data_mem.v` is read (`lw`) or written (`sw`) using the ALU result as the address, with byte-to-word address translation (`>> 2`).
5. **Writeback** — a mux selects between the ALU result and memory read data (`MemToReg`) and writes it back into the register file on the next clock edge.
---
 
## Module Breakdown
 
| File | Role |
|---|---|
| `program_counter.v` | Edge-triggered, synchronous PC register. Updates to the next instruction address every clock cycle. |
| `instruction_mem.v` | Asynchronous instruction ROM. Maps the PC address directly onto the instruction bus. |
| `imm_gen.v` | Combinational immediate extraction/sign-extension for I-type and S-type instruction layouts into a uniform 32-bit value. |
| `control_unit.v` | Main decoder. Maps the 7-bit opcode to datapath control signals: `RegWrite`, `ALUSrc`, `MemRead`, `MemWrite`, `MemToReg`, `Branch`, `ALUop`. |
| `alu_control.v` | Secondary decoder. Combines the 2-bit `ALUop` with `funct3`/`funct7` to produce a 3-bit `ALU_Sel` operation code. |
| `alu.v` | Arithmetic Logic Unit. Supports `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, and `SLT`, plus a `Zero` comparison flag for branch logic. |
| `data_mem.v` | Word-aligned scratchpad RAM. Bridges byte-addressed software semantics to word-indexed hardware storage via address shifting. |
| `register_file.v`* | 32 x 32-bit general-purpose register bank with dual asynchronous reads and one synchronous write. |
 
\* *Confirm exact filename against your `RISC_V_CORE.srcs/sources_1` directory — update if it differs.*
 
The top-level module (e.g. `riscv_core.v`) instantiates and wires together all of the above into the complete single-cycle datapath.
 
---
 
## Control Signal Matrix
 
The Control Unit decodes the 7-bit opcode into the following signal combinations:
 
| Opcode `[6:0]` | Instruction Type | RegWrite | ALUSrc | MemRead | MemWrite | MemToReg | Branch | ALUop `[1:0]` | ALU Action |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| `0110011` | **R-Type** (e.g. `add`) | 1 | 0 | 0 | 0 | 0 | 0 | `10` | Decoded by `funct3`/`funct7` |
| `0010011` | **I-Type** (e.g. `addi`) | 1 | 1 | 0 | 0 | 0 | 0 | `10` | Decoded by `funct3` |
| `0000011` | **Load** (`lw`) | 1 | 1 | 1 | 0 | 1 | 0 | `00` | Forced ADD (address calc) |
| `0100011` | **Store** (`sw`) | 0 | 1 | 0 | 1 | 0 | 0 | `00` | Forced ADD (address calc) |
 
`ALUSrc` selects the ALU's second operand: `0` routes the register file's `rs2` value, `1` routes the sign-extended immediate from `imm_gen.v`.
 
---
 
## Repository Structure
 
This is a **Xilinx Vivado project**, so the repository follows Vivado's standard generated layout:
 
```
RISC-V-32BIT-Single-Cycle-Core/
├── RISC_V_CORE.srcs/              # Verilog design + simulation sources
│   ├── sources_1/                 #   RTL design files (program_counter.v, alu.v, ...)
│   └── sim_1/                     #   Testbench(es), e.g. riscv_tb_large.v
├── RISC_V_CORE.sim/
│   └── sim_1/behav/xsim/          # XSIM behavioral simulation artifacts/logs
├── RISC_V_CORE.hw/                # Hardware (synthesis/implementation) run data
├── RISC_V_CORE.ip_user_files/     # Vivado IP cache/metadata
├── RISC_V_CORE.cache/             # Vivado internal cache
├── RISC_V_CORE.xpr                # Vivado project file — open this in Vivado
├── riscv_tb_behav.wcfg            # Saved waveform configuration for the testbench
└── .gitignore.txt
```
 
> If you're browsing the repo for the first time, the design and testbench Verilog files live under `RISC_V_CORE.srcs/sources_1` and `RISC_V_CORE.srcs/sim_1` respectively — everything else is Vivado-generated project scaffolding.
 
---
 
## Verification & Test Suite
 
Validation is done with a structural testbench, **`riscv_tb_large.v`**, which drives the core, monitors internal signals at runtime, and logs execution to both the Tcl console and a waveform viewer.
 
The testbench loads a **30-instruction program** into instruction memory via `$readmemh` from `initialize.mem`. A representative excerpt:
 
```text
// Instruction Memory Trace Snippet (initialize.mem)
00500093   // addi x1, x0, 5     -> x1 = 5
00A00113   // addi x2, x0, 10    -> x2 = 10
00208133   // add  x2, x1, x2    -> x2 = 5 + 10 = 15 (0xF)
00712223   // sw   x7, 4(x2)     -> store x7 to RAM at [x2 + 4]
00412383   // lw   x7, 4(x2)     -> load back from [x2 + 4] into x7
```
 
This exercises immediate loads, register-register arithmetic, and the full store → load round trip through `data_mem.v`.
 
**What to check in the waveform / Tcl log:**
- `ALUSrc` drops to `0` during R-type instructions (pure register-to-register ALU ops).
- `mem_read` / `mem_write` pulse correctly around `lw` / `sw` boundaries.
- The writeback mux correctly routes ALU results vs. memory read data back into the register file.
- Register values match the expected results of each instruction in `initialize.mem`.
---
 
## Getting Started
 
### Prerequisites
- **Xilinx Vivado** (2020.1 or later recommended)
- No external toolchain is required — instruction memory is preloaded directly from a `.mem` hex file, so no separate RISC-V assembler/compiler step is needed to run the existing test program.
### Running the simulation
 
1. **Clone the repository:**
```bash
   git clone https://github.com/kanishkraj-ops/RISC-V-32BIT-Single-Cycle-Core.git
```
 
2. **Open the project in Vivado:**
   Launch Vivado → `Open Project` → select `RISC_V_CORE.xpr`.
3. **Confirm the memory file path:**
   Make sure `initialize.mem` is present in the active simulation directory
   (`RISC_V_CORE.sim/sim_1/behav/xsim/`), since `$readmemh` resolves it relative to the simulation working directory.
4. **Set the testbench as top:**
   In the Vivado **Sources** tab, right-click `riscv_tb_large.v` → **Set as Top**.
5. **Run the simulation:**
   `Run Simulation` → `Run Behavioral Simulation`.
6. **Extend the simulation time:**
   Set the simulation run time to at least **400 ns** to capture all 30 instructions, then inspect:
   - The **waveform viewer** (preloaded via `riscv_tb_behav.wcfg`)
   - The **Tcl Console**, which prints a register readout log as instructions execute
### Writing your own test program
 
To run custom instructions, hand-assemble RV32I machine code (or generate it with any RV32I assembler) into 32-bit hex words, one per line, and replace the contents of `initialize.mem`. Re-run the behavioral simulation afterward.
 
---
 
## Sample Simulation Output
 
Example of the kind of trace you should see for the snippet above:
 
| Cycle | Instruction | Effect |
|---|---|---|
| 1 | `addi x1, x0, 5` | `x1 = 0x00000005` |
| 2 | `addi x2, x0, 10` | `x2 = 0x0000000A` |
| 3 | `add x2, x1, x2` | `x2 = 0x0000000F` |
| 4 | `sw x7, 4(x2)` | `MEM[x2+4] = x7` |
| 5 | `lw x7, 4(x2)` | `x7 = MEM[x2+4]` |
 
---
 
## Roadmap
 
Planned/possible extensions for future work:
 
- [ ] Branch instructions (`beq`, `bne`, etc.) and jump instructions (`jal`, `jalr`)
- [ ] Full RV32I opcode coverage (`lui`, `auipc`, remaining load/store widths: `lb`, `lh`, `sb`, `sh`)
- [ ] FPGA board constraints (`.xdc`) and physical synthesis/implementation
- [ ] Hazard handling groundwork in preparation for a pipelined successor core
- [ ] Automated regression test suite (beyond the single large testbench)
---
 
## License
 
This project is licensed under the **MIT License**. See [`LICENSE`](LICENSE) for details.
 
---
 
## Acknowledgments
 
Built as a structural, ground-up study of the classic single-cycle RISC datapath (in the spirit of the Patterson & Hennessy / Harris & Harris single-cycle MIPS/RISC-V designs), implemented and verified using the Xilinx Vivado toolchain.
 
