module decode (
    input logic [31:0]  instr,

    //register addresses from instruction bits
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rd_addr,

    //control signals
    output logic [3:0]  alu_op,
    output logic        alu_src,   //0 = use rs2, 1 = use immediate
    output logic        rd_we,     //register write enable
    output logic        mem_read,  //load from memory
    output logic        mem_write, //store to memory
    output logic        mem_to_reg,//0 = ALU result, 1 = memory data
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        lui,
    output logic        auipc,

    //sign extended immediate
    output logic [31:0] imm
);

    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    always_comb begin
        alu_op    = 4'd0;
        alu_src   = 0;
        rd_we     = 0;
        mem_read  = 0;
        mem_write = 0;
        mem_to_reg= 0;
        branch    = 0;
        jal       = 0;
        jalr      = 0;
        imm       = 32'b0;
        lui       = 0; 
        auipc     = 0;
        case(instr[6:0])
            7'b0110011 : // R-type
            begin 
                rd_we = 1; // R-type alwasy writes resutl to rd
                case(instr[14:12])
                    3'b000 : begin
                        if (instr[30] == 0) alu_op = 4'd0;
                        else                alu_op = 4'd1;
                    end
                    3'b111 : alu_op = 4'd2;
                    3'b110 : alu_op = 4'd3;
                    3'b100 : alu_op = 4'd4;
                    3'b001 : alu_op = 4'd5;
                    3'b101 : begin
                        if (instr[30] == 0) alu_op = 4'd6;
                        else                alu_op = 4'd7;
                    end
                    3'b010 : alu_op = 4'd8;
                    3'b011 : alu_op = 4'd9;
                endcase
            end
            7'b0010011 : begin //I-type arithmetic
                rd_we = 1;
                alu_src = 1;
                imm = {{20{instr[31]}}, instr[31:20]};
                case(instr[14:12])
                    3'b000 : alu_op = 4'd0;
                    3'b111 : alu_op = 4'd2;
                    3'b110 : alu_op = 4'd3;
                    3'b100 : alu_op = 4'd4;
                    3'b001 : alu_op = 4'd5;
                    3'b101 : begin
                        if (instr[30] == 0) alu_op = 4'd6;
                        else                alu_op = 4'd7;
                    end
                    3'b010 : alu_op = 4'd8;
                    3'b011 : alu_op = 4'd9;
                endcase
            end
            7'b0000011 : begin //I-type loads
                rd_we      = 1;
                alu_src    = 1;
                mem_read   = 1;
                mem_to_reg = 1;
                imm        = {{20{instr[31]}}, instr[31:20]};
            end
            7'b0100011 : begin //S-type
                alu_src = 1;
                mem_write = 1;
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            7'b1100011 : begin //B-type
                branch = 1;
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            7'b1101111 : begin //J-type JAL
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                rd_we = 1;
                jal = 1;
            end
            7'b1100111 : begin //J-type JALR
                imm = {{20{instr[31]}}, instr[31:20]};
                rd_we = 1;
                jalr = 1;
                alu_src = 1;
            end
            7'b0110111 : begin // LUI
                rd_we = 1;
                lui   = 1;
                imm = {instr[31:12], 12'b0};
            end
            7'b0010111 : begin //AUIPC
                rd_we = 1;
                auipc = 1;
                imm = {instr[31:12], 12'b0};
            end
        endcase
    end


    

endmodule