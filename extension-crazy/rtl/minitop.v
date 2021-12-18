
module top(
    input            CLK,
    input            CLKx2,
    input            CLKx4,
    input            nGOE,
    output reg [7:0] OUTD, 
    input [7:0]      ALU,
    input            nOL,
    input [7:0]      RAL,
    output [18:8]    RAH,
    output           nROE,
    output           nRWE,
    inout [7:0]      RD,
    output           nAE,
    inout [7:0]      GBUS,
    input [15:8]     GAH,
    input            nGWE,
    output           nACTRL,
    output [1:0]     nADEV,
    input [4:3]      XIN,
    input [2:0]      MISO,
    output           MOSI,
    output           SCK,
    output [1:0]     nSS
);

   /* OUT Register (like a 74HC377) */
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   assign RAH = { 3'b000, GAH };
   assign nROE = nGOE;
   assign nRWE = nGWE;
   assign RD = (nGOE) ? GBUS : 8'bZZZZZZZZ;
   assign nAE = 1'b0;
   assign GBUS = (nGOE) ? 8'bZZZZZZZZ : RD;
   assign nACTRL = 1'b1;
   assign nADEV = 2'b11;
   assign MOSI = 1'b1;
   assign SCK = 1'b0;
   assign nSS = 2'b11;
   
endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
