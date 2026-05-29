module csr (
    input  logic        clk,
    input  logic        reset,

    // read port (combinational)
    input  logic [11:0] raddr,
    output logic [31:0] rdata,

    // write port
    input  logic [11:0] waddr,
    input  logic [31:0] wdata,
    input  logic [1:0]  wop,     // 01=write, 10=set, 11=clear

    // trap inputs (from pipeline)
    input  logic        trap,       // ecall or illegal instr
    input  logic [31:0] trap_pc,    // PC of the trapping instruction
    input  logic [31:0] trap_cause, // mcause value
    input  logic [31:0] trap_val,   // mtval value

    // mret input
    input  logic        mret,

    // trap output (to PC mux)
    output logic [31:0] mtvec_out,
    output logic [31:0] mepc_out
);
    logic [31:0] mstatus_r, mie_r, mtvec_r, mscratch_r;
    logic [31:0] mepc_r, mcause_r, mtval_r, mip_r;
    logic [63:0] cycle_r, instret_r;
    always_comb begin
        case (raddr)
            12'h300: rdata = mstatus_r;
            12'h304: rdata = mie_r;
            12'h305: rdata = mtvec_r;
            12'h340: rdata = mscratch_r;
            12'h341: rdata = mepc_r;
            12'h342: rdata = mcause_r;
            12'h343: rdata = mtval_r;
            12'h344: rdata = mip_r;
            12'hF14: rdata = 32'h0;          // mhartid always 0
            12'hC00: rdata = cycle_r[31:0];
            12'hC02: rdata = instret_r[31:0];
            default: rdata = 32'h0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            mstatus_r  <= 32'h0;
            mie_r      <= 32'h0;
            mtvec_r    <= 32'h0;
            mscratch_r <= 32'h0;
            mepc_r     <= 32'h0;
            mcause_r   <= 32'h0;
            mtval_r    <= 32'h0;
            mip_r      <= 32'h0;
            cycle_r    <= 64'h0;
            instret_r  <= 64'h0;
        end else begin
            cycle_r <= cycle_r + 1;

            if (trap) begin
                mepc_r          <= trap_pc;
                mcause_r        <= trap_cause;
                mtval_r         <= trap_val;
                mstatus_r[7]    <= mstatus_r[3]; // MPIE = MIE
                mstatus_r[3]    <= 1'b0;         // clear MIE
            end else if (mret) begin
                mstatus_r[3]    <= mstatus_r[7]; // MIE = MPIE
                mstatus_r[7]    <= 1'b1;         // MPIE = 1
            end else if (wop != 2'b00) begin
                case (waddr)
                    12'h300: mstatus_r  <= wop==2'd1 ? wdata : wop==2'd2 ? mstatus_r|wdata  : mstatus_r&~wdata;
                    12'h304: mie_r      <= wop==2'd1 ? wdata : wop==2'd2 ? mie_r|wdata      : mie_r&~wdata;
                    12'h305: mtvec_r    <= wop==2'd1 ? wdata : wop==2'd2 ? mtvec_r|wdata    : mtvec_r&~wdata;
                    12'h340: mscratch_r <= wop==2'd1 ? wdata : wop==2'd2 ? mscratch_r|wdata : mscratch_r&~wdata;
                    12'h341: mepc_r     <= wop==2'd1 ? wdata : wop==2'd2 ? mepc_r|wdata     : mepc_r&~wdata;
                    default: ;
                endcase
            end
        end
    end



    assign mtvec_out = mtvec_r;
    assign mepc_out  = mepc_r;

endmodule