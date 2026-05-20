module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  op,
    output logic [31:0] result
);

always_comb 
begin
    case(op)
        4'd0 : result = a + b;
        4'd1 : result = a - b;
        4'd2 : result = a & b;
        4'd3 : result = a | b;
        4'd4 : result = a ^ b;
        4'd5 : result = a << b[4:0];
        4'd6 : result = a >> b[4:0];
        4'd7 : result = a >>> b[4:0];
        4'd8 : result = ($signed(a) < $signed(b)) ? 1 : 0;
        4'd9 : result = (a < b) ? 1 : 0;
        default : result = 32'b0;
    endcase
end

endmodule