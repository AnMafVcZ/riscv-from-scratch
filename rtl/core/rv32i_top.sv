typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instr;
} if_id_t;

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    logic [4:0]  rd_addr;
    logic [3:0]  alu_op;
    logic [2:0]  funct3;
    logic        alu_src;
    logic        rd_we;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        branch;
    logic        jal;
    logic        jalr;
    logic        lui;
    logic        auipc;
} id_ex_t;

typedef struct packed {
    logic [31:0] alu_result;
    logic [31:0] rs2_data;
    logic [31:0] pc_branch;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    logic        rd_we;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        branch_taken;
    logic        jal;
    logic        jalr;
} ex_mem_t;

typedef struct packed {
    logic [31:0] alu_result;
    logic [31:0] load_data;
    logic [31:0] pc_plus4;
    logic [4:0]  rd_addr;
    logic        rd_we;
    logic        mem_to_reg;
    logic        jal;
    logic        jalr;
} mem_wb_t;

module rv32i_top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] debug_dmem0
    
);

if_id_t  if_id_reg;
id_ex_t  id_ex_reg;
ex_mem_t ex_mem_reg;
mem_wb_t mem_wb_reg;



endmodule