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
