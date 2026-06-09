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
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
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
    logic [11:0] csr_addr;
    logic [1:0]  csr_op;
    logic        csr_use_imm;
    logic        is_ecall;
    logic        is_mret;
    logic [31:0] raw_instr;
    logic        is_illegal;
} id_ex_t;

typedef struct packed {
    logic [31:0] alu_result;
    logic [31:0] rs2_data;
    logic [31:0] pc_branch;
    logic [31:0] pc_plus4;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    logic        rd_we;
    logic        mem_read;
    logic        mem_write;
    logic        mem_to_reg;
    logic        branch_taken;
    logic        jal;
    logic        jalr;
    logic [31:0] csr_rdata;
    logic        is_csr;
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
    logic [31:0] csr_rdata;
    logic        is_csr;
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

// memories
logic [31:0] imem [0:1023];
logic [31:0] dmem [0:1023] /*verilator public*/;
initial begin
    string hex_file;
    if (!$value$plusargs("HEX=%s", hex_file))
        hex_file = "../tests/hello_word.hex";
    $readmemh(hex_file, imem);
end

// ── Hazard detection ─────────────────────────────
logic load_use_stall;
assign load_use_stall = id_ex_reg.mem_read &&
                        ((id_ex_reg.rd_addr == id_rs1_addr) ||
                         (id_ex_reg.rd_addr == id_rs2_addr));

logic flush;
assign flush = ex_mem_reg.branch_taken | ex_mem_reg.jal | ex_mem_reg.jalr | trap_flush;

logic trap_flush;
assign trap_flush = id_ex_reg.is_ecall | id_ex_reg.is_mret | id_ex_reg.is_illegal | take_irq;




// ── IF ───────────────────────────────────────────
logic [31:0] pc, pc_next;

always_ff @(posedge clk) begin
    if (reset) pc <= 32'b0;
    else if (!load_use_stall) pc <= pc_next;
end

always_ff @(posedge clk) begin
    if (reset || flush) if_id_reg <= '0;
    else if (!load_use_stall) begin
        if_id_reg.pc    <= pc;
        if_id_reg.instr <= imem[pc[11:2]];
    end
end

// ── ID ───────────────────────────────────────────
logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
logic [3:0]  id_alu_op;
logic [2:0]  id_funct3;
logic        id_alu_src, id_rd_we, id_mem_read, id_mem_write, id_mem_to_reg;
logic        id_branch, id_jal, id_jalr, id_lui, id_auipc;
logic [31:0] id_imm;
logic [31:0] id_rs1_data, id_rs2_data;
logic [11:0] id_csr_addr;
logic [1:0]  id_csr_op;
logic        id_csr_use_imm;
logic        id_is_ecall;
logic        id_is_mret;
logic        id_is_illegal;


decode u_decode (
    .instr      (if_id_reg.instr),
    .rs1_addr   (id_rs1_addr),
    .rs2_addr   (id_rs2_addr),
    .rd_addr    (id_rd_addr),
    .alu_op     (id_alu_op),
    .alu_src    (id_alu_src),
    .rd_we      (id_rd_we),
    .mem_read   (id_mem_read),
    .mem_write  (id_mem_write),
    .mem_to_reg (id_mem_to_reg),
    .branch     (id_branch),
    .jal        (id_jal),
    .jalr       (id_jalr),
    .imm        (id_imm),
    .lui        (id_lui),
    .auipc      (id_auipc),
    .csr_addr   (id_csr_addr),
    .csr_op     (id_csr_op),
    .csr_use_imm(id_csr_use_imm),
    .is_ecall   (id_is_ecall),
    .is_mret    (id_is_mret),
    .is_illegal  (id_is_illegal)
);

regfile u_regfile (
    .clk      (clk),
    .rs1_addr (id_rs1_addr),
    .rs2_addr (id_rs2_addr),
    .rd_addr  (mem_wb_reg.rd_addr),
    .rd_data  (wb_rd_data),
    .rd_we    (mem_wb_reg.rd_we),
    .rs1_data (id_rs1_data),
    .rs2_data (id_rs2_data)
);

always_ff @(posedge clk) begin
    if (reset || load_use_stall || flush) id_ex_reg <= '0;
    else begin
        id_ex_reg.pc         <= if_id_reg.pc;
        id_ex_reg.rs1_data   <= id_rs1_data;
        id_ex_reg.rs2_data   <= id_rs2_data;
        id_ex_reg.imm        <= id_imm;
        id_ex_reg.rd_addr    <= id_rd_addr;
        id_ex_reg.rs1_addr   <= id_rs1_addr;
        id_ex_reg.rs2_addr   <= id_rs2_addr;
        id_ex_reg.alu_op     <= id_alu_op;
        id_ex_reg.funct3     <= if_id_reg.instr[14:12];
        id_ex_reg.alu_src    <= id_alu_src;
        id_ex_reg.rd_we      <= id_rd_we;
        id_ex_reg.mem_read   <= id_mem_read;
        id_ex_reg.mem_write  <= id_mem_write;
        id_ex_reg.mem_to_reg <= id_mem_to_reg;
        id_ex_reg.branch     <= id_branch;
        id_ex_reg.jal        <= id_jal;
        id_ex_reg.jalr       <= id_jalr;
        id_ex_reg.lui        <= id_lui;
        id_ex_reg.auipc      <= id_auipc;
        id_ex_reg.csr_addr    <= id_csr_addr;
        id_ex_reg.csr_op      <= id_csr_op;
        id_ex_reg.csr_use_imm <= id_csr_use_imm;
        id_ex_reg.is_ecall    <= id_is_ecall;
        id_ex_reg.is_mret     <= id_is_mret;
        id_ex_reg.raw_instr  <= if_id_reg.instr;
        id_ex_reg.is_illegal <= id_is_illegal;
    end
end

// ── EX ───────────────────────────────────────────
logic [31:0] ex_alu_a, ex_alu_b, ex_alu_result;
logic        ex_branch_taken;

// forwarding mux selects: 00=normal, 10=EX/MEM, 01=MEM/WB
logic [1:0] forwardA, forwardB;

always_comb begin
    forwardA = 2'b00;
    forwardB = 2'b00;

    // EX/MEM forward (higher priority)
    if (ex_mem_reg.rd_we && ex_mem_reg.rd_addr != 0 &&
        ex_mem_reg.rd_addr == id_ex_reg.rs1_addr)
        forwardA = 2'b10;

    if (ex_mem_reg.rd_we && ex_mem_reg.rd_addr != 0 &&
        ex_mem_reg.rd_addr == id_ex_reg.rs2_addr)
        forwardB = 2'b10;

    // MEM/WB forward (lower priority, only if EX/MEM didn't match)
    if (mem_wb_reg.rd_we && mem_wb_reg.rd_addr != 0 &&
        mem_wb_reg.rd_addr == id_ex_reg.rs1_addr && forwardA == 2'b00)
        forwardA = 2'b01;

    if (mem_wb_reg.rd_we && mem_wb_reg.rd_addr != 0 &&
        mem_wb_reg.rd_addr == id_ex_reg.rs2_addr && forwardB == 2'b00)
        forwardB = 2'b01;
end

logic [31:0] ex_rs1_fwd, ex_rs2_fwd;

assign ex_rs1_fwd = forwardA == 2'b10 ? ex_mem_reg.alu_result :
                    forwardA == 2'b01 ? wb_rd_data            :
                                        id_ex_reg.rs1_data;

assign ex_rs2_fwd = forwardB == 2'b10 ? ex_mem_reg.alu_result :
                    forwardB == 2'b01 ? wb_rd_data            :
                                        id_ex_reg.rs2_data;

assign ex_alu_a = id_ex_reg.auipc ? id_ex_reg.pc :
                  id_ex_reg.lui   ? 32'b0         :
                                    ex_rs1_fwd;

assign ex_alu_b = id_ex_reg.alu_src ? id_ex_reg.imm : ex_rs2_fwd;


alu u_alu (
    .a      (ex_alu_a),
    .b      (ex_alu_b),
    .op     (id_ex_reg.alu_op),
    .result (ex_alu_result)
);

// CSR
logic [31:0] ex_csr_wdata, ex_csr_rdata;
logic [31:0] ex_mtvec, ex_mepc;
logic        ex_trap;
logic        ex_irq_timer;
logic        take_irq;

logic [31:0] ex_trap_cause, ex_trap_val;
logic        ex_exception;
assign ex_csr_wdata  = id_ex_reg.csr_use_imm ? {27'b0, id_ex_reg.rs1_addr} : ex_rs1_fwd;
assign ex_exception  = id_ex_reg.is_ecall | id_ex_reg.is_illegal;
assign take_irq      = ex_irq_timer & !ex_exception;
assign ex_trap       = ex_exception | take_irq;
assign ex_trap_cause = take_irq             ? 32'h80000007 :
                       id_ex_reg.is_ecall   ? 32'd11       : 32'd2;
assign ex_trap_val   = id_ex_reg.is_illegal ? id_ex_reg.raw_instr : 32'd0;
csr u_csr (
    .clk        (clk),
    .reset      (reset),
    .raddr      (id_ex_reg.csr_addr),
    .rdata      (ex_csr_rdata),
    .waddr      (id_ex_reg.csr_addr),
    .wdata      (ex_csr_wdata),
    .wop        (id_ex_reg.csr_op),
    .trap       (ex_trap),
    .trap_pc    (id_ex_reg.pc),
    .trap_cause (ex_trap_cause),
    .trap_val   (ex_trap_val),
    .mret       (id_ex_reg.is_mret),
    .mtvec_out  (ex_mtvec),
    .mepc_out   (ex_mepc),
    .irq_timer  (ex_irq_timer)

);


always_comb begin
    case (id_ex_reg.funct3)
        3'b000: ex_branch_taken = (id_ex_reg.rs1_data == id_ex_reg.rs2_data);
        3'b001: ex_branch_taken = (id_ex_reg.rs1_data != id_ex_reg.rs2_data);
        3'b100: ex_branch_taken = ($signed(id_ex_reg.rs1_data) < $signed(id_ex_reg.rs2_data));
        3'b101: ex_branch_taken = ($signed(id_ex_reg.rs1_data) >= $signed(id_ex_reg.rs2_data));
        3'b110: ex_branch_taken = (id_ex_reg.rs1_data < id_ex_reg.rs2_data);
        3'b111: ex_branch_taken = (id_ex_reg.rs1_data >= id_ex_reg.rs2_data);
        default: ex_branch_taken = 0;
    endcase
end

always_ff @(posedge clk) begin
    if (reset) ex_mem_reg <= '0;
    else begin
        ex_mem_reg.alu_result   <= ex_alu_result;
        ex_mem_reg.rs2_data     <= ex_rs2_fwd;
        ex_mem_reg.pc_branch    <= id_ex_reg.pc + id_ex_reg.imm;
        ex_mem_reg.pc_plus4     <= id_ex_reg.pc + 32'd4;
        ex_mem_reg.rd_addr      <= id_ex_reg.rd_addr;
        ex_mem_reg.funct3       <= id_ex_reg.funct3;
        ex_mem_reg.rd_we        <= id_ex_reg.rd_we;
        ex_mem_reg.mem_read     <= id_ex_reg.mem_read;
        ex_mem_reg.mem_write    <= id_ex_reg.mem_write;
        ex_mem_reg.csr_rdata <= ex_csr_rdata;
        ex_mem_reg.is_csr    <= (id_ex_reg.csr_op != 2'b00);
        ex_mem_reg.mem_to_reg   <= id_ex_reg.mem_to_reg;
        ex_mem_reg.branch_taken <= id_ex_reg.branch & ex_branch_taken;
        ex_mem_reg.jal          <= id_ex_reg.jal;
        ex_mem_reg.jalr         <= id_ex_reg.jalr;
    end
end

// ── MEM ──────────────────────────────────────────
logic [31:0] mem_rdata;
logic [31:0] mem_load_data;
logic [3:0]  mem_be;
logic [31:0] mem_wdata;

lsu u_lsu (
    .rs2_data  (ex_mem_reg.rs2_data),
    .funct3    (ex_mem_reg.funct3),
    .addr      (ex_mem_reg.alu_result),
    .mem_write (ex_mem_reg.mem_write),
    .mem_read  (ex_mem_reg.mem_read),
    .mem_wdata (mem_wdata),
    .mem_rdata (mem_rdata),
    .be        (mem_be),
    .load_data (mem_load_data)
);

assign mem_rdata = dmem[ex_mem_reg.alu_result[11:2]];

always_ff @(posedge clk) begin
    if (ex_mem_reg.mem_write) begin
        if (mem_be[0]) dmem[ex_mem_reg.alu_result[11:2]][7:0]   <= mem_wdata[7:0];
        if (mem_be[1]) dmem[ex_mem_reg.alu_result[11:2]][15:8]  <= mem_wdata[15:8];
        if (mem_be[2]) dmem[ex_mem_reg.alu_result[11:2]][23:16] <= mem_wdata[23:16];
        if (mem_be[3]) dmem[ex_mem_reg.alu_result[11:2]][31:24] <= mem_wdata[31:24];
    end
end

always_ff @(posedge clk) begin
    if (reset) mem_wb_reg <= '0;
    else begin
        mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
        mem_wb_reg.csr_rdata <= ex_mem_reg.csr_rdata;
        mem_wb_reg.is_csr    <= ex_mem_reg.is_csr;
        mem_wb_reg.load_data  <= mem_load_data;
        mem_wb_reg.pc_plus4   <= ex_mem_reg.pc_branch - ex_mem_reg.alu_result + ex_mem_reg.alu_result; // placeholder
        mem_wb_reg.rd_addr    <= ex_mem_reg.rd_addr;
        mem_wb_reg.rd_we      <= ex_mem_reg.rd_we;
        mem_wb_reg.mem_to_reg <= ex_mem_reg.mem_to_reg;
        mem_wb_reg.jal        <= ex_mem_reg.jal;
        mem_wb_reg.jalr       <= ex_mem_reg.jalr;
    end
end

// ── WB ───────────────────────────────────────────
logic [31:0] wb_rd_data;

assign wb_rd_data = mem_wb_reg.jal | mem_wb_reg.jalr ? mem_wb_reg.pc_plus4  :
                    mem_wb_reg.is_csr                 ? mem_wb_reg.csr_rdata :
                    mem_wb_reg.mem_to_reg             ? mem_wb_reg.load_data :
                                                        mem_wb_reg.alu_result;
// ── PC next ───────────────────────────────────────
assign pc_next = trap_flush & id_ex_reg.is_mret                                      ? ex_mepc  :
                 trap_flush & (id_ex_reg.is_ecall | id_ex_reg.is_illegal | take_irq) ? ex_mtvec :
                 ex_mem_reg.jalr         ? ex_mem_reg.alu_result & ~32'h1 :
                 ex_mem_reg.jal         ? ex_mem_reg.pc_branch            :
                 ex_mem_reg.branch_taken ? ex_mem_reg.pc_branch            :
                                          pc + 4;

assign debug_dmem0 = dmem[0];

`ifdef VERILATOR
integer cycle_count;
always @(posedge clk) begin
    if (reset) cycle_count <= 0;
    else       cycle_count <= cycle_count + 1;
end

always @(posedge clk) begin
    if (!reset && $test$plusargs("TRACE")) begin
        $display("[%4d] IF=%08h | ID=%08h:%08h | EX=%08h | MEM=addr=%08h rw=%b%b | WB=x%02d=%08h we=%b | %s%s",
            cycle_count,
            pc,
            if_id_reg.pc, if_id_reg.instr,
            id_ex_reg.pc,
            ex_mem_reg.alu_result, ex_mem_reg.mem_read, ex_mem_reg.mem_write,
            mem_wb_reg.rd_addr, wb_rd_data, mem_wb_reg.rd_we,
            load_use_stall ? "STALL " : "      ",
            flush          ? "FLUSH"  : ""
        );
    end
end
`endif

endmodule