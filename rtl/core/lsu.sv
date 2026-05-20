module lsu (
    input  logic [31:0] addr,
    input  logic [31:0] rs2_data,   // data to store
    input  logic [31:0] mem_rdata,  // raw word from memory
    input  logic [2:0]  funct3,     // LB/LH/LW/LBU/LHU/SB/SH/SW
    input  logic        mem_read,
    input  logic        mem_write,
    output logic [31:0] mem_wdata,  // data to write to memory
    output logic [3:0]  be,         // byte enables
    output logic [31:0] load_data   // sign/zero extended load result
);

always_comb begin
    // defaults
    be       = 4'b1111;
    mem_wdata = rs2_data;
    load_data = 32'b0;
    if (mem_write) begin
        case(funct3)
            3'b000 : begin // SB - 1 byte
            case(addr[1:0])
                2'b00 : begin
                    be = 4'b0001;
                    mem_wdata = {24'b0,rs2_data[7:0]};
                end
                2'b01 : begin 
                    be = 4'b0010;
                    mem_wdata = {16'b0, rs2_data[7:0], 8'b0};
                end
                2'b10 : begin 
                    be = 4'b0100;
                    mem_wdata = {8'b0, rs2_data[7:0], 16'b0};
                end
                2'b11 : begin
                    be = 4'b1000;
                    mem_wdata = {rs2_data[7:0], 24'b0};
                end
            endcase
            end
            3'b001 : begin // SH - 2 bytes 
                if(!addr[1])begin
                    be = 4'b0011;
                    mem_wdata = {16'b0,rs2_data[15:0]};
                end
                else begin
                    be = 4'b1100;
                    mem_wdata = {rs2_data[15:0], 16'b0};
                end
            end 
            3'b010 : begin// SW - 4 bytes
                be = 4'b1111;
                mem_wdata = rs2_data;
            end
            default : ;
        endcase
    end
    if (mem_read) begin
        case(funct3)
            3'b000 : begin // LB
            case(addr[1:0])
                2'b00: load_data = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                2'b01: load_data = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                2'b10: load_data = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                2'b11: load_data = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
            endcase
            end
            3'b001 : begin // LH
            if(!addr[1])
                load_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
            else
                load_data = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
            end
            3'b010 : begin // LW
                load_data = mem_rdata;
            end
            3'b100 : begin // LBU
            case(addr[1:0])
                2'b00: load_data = {{24{1'b0}}, mem_rdata[7:0]};
                2'b01: load_data = {{24{1'b0}}, mem_rdata[15:8]};
                2'b10: load_data = {{24{1'b0}}, mem_rdata[23:16]};
                2'b11: load_data = {{24{1'b0}}, mem_rdata[31:24]};
            endcase
            end
            3'b101 : begin // LHU
            if(!addr[1])
                load_data = {{16{1'b0}}, mem_rdata[15:0]};
            else
                load_data = {{16{1'b0}}, mem_rdata[31:16]};
            end
            default : ;
        endcase
    end
end
endmodule