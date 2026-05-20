module regfile (
    input logic clk,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [4:0] rd_addr,
    input logic [31:0] rd_data,
    input logic rd_we,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] regfile [31:0];

    assign rs1_data = (rs1_addr == 0) ? 32'b0 : regfile[rs1_addr];
    assign rs2_data = (rs2_addr == 0) ? 32'b0 : regfile[rs2_addr];

    always_ff@(posedge clk)
    begin
        if(rd_we && (rd_addr != 0))
            regfile[rd_addr] <= rd_data;
    end

    
endmodule