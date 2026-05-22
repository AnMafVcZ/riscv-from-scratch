module rv32i_top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] debug_dmem0
);

// PC
logic [31:0] pc, pc_next;

// instruction
logic [31:0] instr;

// decode outputs
logic [4:0]  rs1_addr, rs2_addr, rd_addr;
logic [3:0]  alu_op;
logic        alu_src, rd_we, mem_read, mem_write, mem_to_reg;
logic        branch, jal, jalr;
logic [31:0] imm;
logic        lui, auipc;

// regfile outputs
logic [31:0] rs1_data, rs2_data;

// ALU
logic [31:0] alu_a, alu_b, alu_result;

// LSU
logic [31:0] mem_wdata, load_data;
logic [3:0]  be;
logic [31:0] addr, mem_rdata;

// writeback
logic [31:0] rd_data;

always_ff @(posedge clk) begin
    if (reset) pc <= 32'b0;
    else       pc <= pc_next;
end

logic [31:0] imem [0:1023]; // 4KB
assign instr = imem[pc[11:2]]; // word-addressed, ignore bottom 2 bits
initial $readmemh("../tests/hello_word.hex", imem);

logic [31:0] dmem [0:1023] /*verilator public*/; // 4KB

always_ff @(posedge clk) begin
    if (mem_write) begin
        if (be[0]) dmem[addr[11:2]][7:0]   <= mem_wdata[7:0];
        if (be[1]) dmem[addr[11:2]][15:8]  <= mem_wdata[15:8];
        if (be[2]) dmem[addr[11:2]][23:16] <= mem_wdata[23:16];
        if (be[3]) dmem[addr[11:2]][31:24] <= mem_wdata[31:24];
    end
end
assign mem_rdata = dmem[addr[11:2]];
assign addr = alu_result;

decode u_decode (
    .instr      (instr),
    .rs1_addr   (rs1_addr),
    .rs2_addr   (rs2_addr),
    .rd_addr    (rd_addr),
    .alu_op     (alu_op),
    .alu_src    (alu_src),
    .rd_we      (rd_we),
    .mem_read   (mem_read),
    .mem_write  (mem_write),
    .mem_to_reg (mem_to_reg),
    .branch     (branch),
    .jal        (jal),
    .jalr       (jalr),
    .imm        (imm),
    .lui        (lui),
    .auipc      (auipc)
);

regfile u_regfile (
    .clk        (clk),
    .rs1_addr   (rs1_addr),
    .rs2_addr   (rs2_addr),
    .rd_addr    (rd_addr),
    .rd_data    (rd_data),
    .rd_we      (rd_we),
    .rs1_data   (rs1_data),
    .rs2_data   (rs2_data)
);

alu u_alu (
    .a      (alu_a),
    .b      (alu_b),
    .op     (alu_op),
    .result  (alu_result)
);

lsu u_lsu (
    .rs2_data  (rs2_data),
    .funct3    (instr[14:12]),
    .addr      (alu_result),
    .mem_write (mem_write),
    .mem_read  (mem_read),
    .mem_wdata (mem_wdata),
    .mem_rdata (mem_rdata),
    .be        (be),
    .load_data (load_data)
);

assign alu_b = alu_src ? imm : rs2_data;

assign rd_data = jal | jalr  ? pc + 4 :
                 mem_to_reg  ? load_data :
                               alu_result;

logic branch_taken;

always_comb begin
    case(instr[14:12])
        3'b000: branch_taken = (rs1_data == rs2_data);          // BEQ
        3'b001: branch_taken = (rs1_data != rs2_data);          // BNE
        3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data));  // BLT
        3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
        3'b110: branch_taken = (rs1_data < rs2_data);           // BLTU
        3'b111: branch_taken = (rs1_data >= rs2_data);          // BGEU
        default: branch_taken = 0;
    endcase
end

assign pc_next = jalr              ? (rs1_data + imm) & ~32'h1 :
                 jal               ? pc + imm :
                 branch & branch_taken ? pc + imm :
                                    pc + 4;

assign alu_a = auipc ? pc :
               lui   ? 32'b0 :
                       rs1_data;

assign debug_dmem0 = dmem[0];

endmodule