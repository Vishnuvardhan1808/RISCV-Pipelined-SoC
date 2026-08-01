# 32-bit Pipelined RISC-V SoC with Direct-Mapped Cache & AXI4 Memory Subsystem

## 📌 Project Overview
This repository contains the complete RTL (Register Transfer Level) design and verification environment for a custom **32-bit System-on-Chip (SoC)** based on the **RISC-V (RV32I)** Instruction Set Architecture. 

Written entirely in **Verilog HDL**, this project bridges the gap between a standard educational CPU core and a production-style SoC by integrating a **5-stage pipeline**, dynamic **hazard management**, a **direct-mapped cache**, and an **AXI4 memory controller** interface for robust memory wait-state handling.

---

## 🏗️ System Architecture

### 1. The 5-Stage Pipelined Core (`riscv_pipelined_core.v`)
The core CPU implements the classic 5-stage RISC pipeline, utilizing dedicated inter-stage hardware registers to isolate execution states and maximize operating frequency:

*   **IF (Instruction Fetch):** Calculates the next Program Counter (`pc`) and fetches the 32-bit instruction from the ROM.
*   **ID (Instruction Decode):** Decodes opcodes (`riscv_decoder`), generates immediate values (`imm_gen`), and reads from the dual-port Register File (`register_file`).
*   **EX (Execute):** Performs arithmetic and logical operations via the ALU. 
*   **MEM (Memory):** Interacts with the Data Cache. Susceptible to wait-states.
*   **WB (Write-Back):** Writes computed results or loaded memory data back to the destination register.

### 2. Hazard Resolution & Control
To maintain cycle efficiency and prevent data corruption, two dedicated control units were implemented:
*   **Forwarding Unit (`forwarding_unit.v`):** Resolves **Data Hazards** by bypassing the register file. It intercepts data from the EX/MEM and MEM/WB registers and feeds it directly back into the ALU inputs, eliminating the need for pipeline bubbles during back-to-back dependent instructions.
*   **Hazard Detection Unit (`hazard_detection_unit.v`):** Resolves **Load-Use Hazards** and handles control flow changes (branches/jumps). It detects when a dependent instruction immediately follows a load instruction and inserts a hardware stall (bubble) into the pipeline.

### 3. Memory Subsystem & Cache Interface
*   **Instruction ROM (`instruction_rom.v`):** A hardcoded memory block containing the RISC-V machine code being executed.
*   **Direct-Mapped Data Cache (`direct_mapped_cache.v`):** A level-1 cache subsystem that evaluates hits/misses dynamically.
*   **AXI4 Memory Controller (`axi4_memory_controller.v`):** Governs transactions between the cache and main memory. Upon a cache miss, this controller initiates AXI4-compliant read/write handshakes to trigger a cache line fill.

### 4. Global Freeze Synchronization (`stall_in`)
When a cache miss occurs, main memory latency dictates that the processor must wait. The Cache and Memory Controller assert a global `stall_in` bus. This signal routes back to the CPU, synchronously freezing the `pc`, `if_id_reg`, and `id_ex_reg` to prevent the core from losing its execution state while waiting for data.

---

## 📁 Source Code Hierarchy

The project is structured modularly. The `soc_top.v` file acts as the top-level wrapper interconnecting all sub-modules.

```text
📂 Design Sources
 └── 📄 soc_top.v
     ├── 📄 instruction_rom.v (i_rom)
     ├── 📄 riscv_pipelined_core.v (cpu)
     │    ├── 📄 program_counter.v (pc_inst)
     │    ├── 📄 if_id_reg.v (if_id_inst)
     │    ├── 📄 riscv_decoder.v (decoder_inst)
     │    ├── 📄 imm_gen.v (imm_gen_inst)
     │    ├── 📄 register_file.v (regfile_inst)
     │    ├── 📄 id_ex_reg.v (id_ex_inst)
     │    ├── 📄 hazard_detection_unit.v (hazard_inst)
     │    ├── 📄 forwarding_unit.v (fwd_inst)
     │    ├── 📄 alu.v (alu_inst)
     │    ├── 📄 ex_mem_reg.v (ex_mem_inst)
     │    └── 📄 mem_wb_reg.v (mem_wb_inst)
     ├── 📄 direct_mapped_cache.v (d_cache)
     └── 📄 axi4_memory_controller.v (main_memory)
📂 Simulation Sources
 └── 📄 tb_soc_top.v
