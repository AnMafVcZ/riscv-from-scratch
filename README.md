# RISC-V from Scratch

Building a RISC-V CPU in Verilog from the ground up. Starting with the basics and adding pieces until there's a working processor.

# Stage 1
Creating a single cycle cpu, no pipelining

`regfile.sv`
32 registers that instructions read from and write to, can read from two resgist rs1 and rs2, this is purely combinational. Can write on register per clk, only when write enable is high and never writes to x0.

`alu.sv`
alu takes two 32 bit numbers and operation code then outputs the result, all combination 
| Op code | Name | Operation |
|---|---|---|
| 0 | ADD | a + b |
| 1 | SUB | a - b |
| 2 | AND | a & b |
| 3 | OR | a \| b |
| 4 | XOR | a ^ b |
| 5 | SLL | a << b[4:0] |
| 6 | SRL | a >> b[4:0] |
| 7 | SRA | a >>> b[4:0] |
| 8 | SLT | 1 if a < b (signed) |
| 9 | SLTU | 1 if a < b (unsigned) |

`decode.sv`
takes in 32 bit instr and then it figures out what each part of that instruction tells which register to read, which ALU operation to run, or whether to read or write in memory, and if there is an immediate value, creates the signals that the CPU should follow

| Type   | Opcode  | rd_we | alu_src | mem_read | mem_write | mem_to_reg | branch | jal | jalr |
|--------|---------|-------|---------|----------|-----------|------------|--------|-----|------|
| R      | 0110011 | 1     | 0       | 0        | 0         | 0          | 0      | 0   | 0    |
| I-arith| 0010011 | 1     | 1       | 0        | 0         | 0          | 0      | 0   | 0    |
| I-load | 0000011 | 1     | 1       | 1        | 0         | 1          | 0      | 0   | 0    |
| S      | 0100011 | 0     | 1       | 0        | 1         | 0          | 0      | 0   | 0    |
| B      | 1100011 | 0     | 0       | 0        | 0         | 0          | 1      | 0   | 0    |
| JAL    | 1101111 | 1     | 0       | 0        | 0         | 0          | 0      | 1   | 0    |
| JALR   | 1100111 | 1     | 1       | 0        | 0         | 0          | 0      | 0   | 1    |
| LUI    | 0110111 | 1     | 0       | 0        | 0         | 0          | 0      | 0   | 0    |
| AUIPC  | 0010111 | 1     | 0       | 0        | 0         | 0          | 0      | 0   | 0    |

`lsu.sv`
lsu does the reading and writing memory at the byte/halfword/word level, store takes the values and figures out where to write by setting be, and then concatenates it correctly in mem_wdata. load takes in raw 32-bit word form memory taking the byte halfword or word based on the input, the lower bits of addr, 0 and 1 determine if it is a byte or hlafword if that is what is being used.

`rv32i_top.sv`
wires all four modules together into a complete CPU. Holds the PC register, instruction memory, and data memory. On every clock cycle it fetches an instruction, decodes it, reads registers, runs the ALU, accesses memory if needed, writes the result back, and updates the PC.

Summary 
A single-cycle RV32I CPU, every instruction completes in one clock cycle. An instruction comes in, decode figures out what to do, the ALU computes the result, the LSU handles any memory access, and the result gets written back to the register file. The PC then moves to the next instruction, a branch target, or a jump target.

# Stage 2
Converting the single-cycle CPU into a 5-stage pipeline: IF → ID → EX → MEM → WB. Instead of one instruction per cycle taking the full path, multiple instructions run simultaneously — each in a different stage.

Pipeline registers sit between each stage and hold the outputs so the next stage can read them on the following cycle without getting clobbered by the next instruction coming in behind it.

`rv32i_top.sv` (rewritten)
The top level now defines four pipeline register structs (`if_id_t`, `id_ex_t`, `ex_mem_t`, `mem_wb_t`) and implements all five stages. Each stage reads from the register behind it, does its work, and writes into the register in front of it on the rising clock edge.

**Forwarding**
Without forwarding, an instruction that writes a register can't be read by the next instruction until writeback completes three cycles later. Forwarding detects when EX needs a value that's already computed but not yet written back, and routes it directly:
- EX/MEM forward — result from one instruction ago fed directly into EX inputs
- MEM/WB forward — result from two instructions ago fed into EX inputs

`forwardA` and `forwardB` are 2-bit mux selects: `00` = use register file value, `10` = forward from EX/MEM, `01` = forward from MEM/WB.

**Load-use stall**
Forwarding can't fix a load followed immediately by a dependent instruction — the load result doesn't exist until after the MEM stage, which is the same cycle as the next instruction's EX. One stall cycle is inserted: the PC and IF/ID register freeze, and a bubble (all-zero control signals) is injected into ID/EX. The load result is then available via MEM/WB forwarding one cycle later.

**Branch flush**
Branch targets are resolved in EX. By then two wrong instructions have entered the pipeline behind the branch. When a branch is taken, both IF/ID and ID/EX are zeroed out (flushed) on the next cycle, discarding the wrong instructions.

Summary
A 5-stage pipelined RV32I CPU with full hazard handling. Back-to-back dependent instructions work without any NOPs thanks to forwarding. Load-use hazards are handled with a one-cycle stall. Taken branches flush two pipeline stages and redirect the PC to the correct target.