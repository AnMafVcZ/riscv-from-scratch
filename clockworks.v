module Clockworks
(
   input  CLK,   // clock pin of the board
   input  RESET, // reset pin of the board
   output clk,   // (optionally divided) clock for the design
   output resetn // negative reset for the design
);
   parameter SLOW = 0;

   reg [SLOW:0] slow_CLK = 0;
   always @(posedge CLK) begin
      slow_CLK <= slow_CLK + 1;
   end
   assign clk    = slow_CLK[SLOW];
   assign resetn = !RESET;

endmodule
