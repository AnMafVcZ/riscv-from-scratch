/**
 * Step 1: Blinker
 * DONE
 */

`default_nettype none
`include "clockworks.v"

module SOC (
    input  CLK,        // system clock 
    input  RESET,      // reset button
    output [4:0] LEDS, // system LEDs
    input  RXD,        // UART receive
    output TXD         // UART transmit
);

   wire clk; //interal clk
   wire resetn; //interal reset

// A blinker that counts on 5 bits, wired to the 5 LEDs
   reg [4:0] count = 0;
   always @(posedge clk) begin
      count <= !resetn ? 0 : count + 1;
   end
   
   Clockworks#(
      .SLOW(21) // slows it by 2^21, so it blinks at about 1Hz on a 100MHz board
   ) clockworks (
      .CLK(CLK),
      .RESET(RESET),
      .clk(clk),
      .resetn(resetn)
   );

   assign LEDS = count;
   assign TXD  = 1'b0; // not used for now
endmodule