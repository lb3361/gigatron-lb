
module main(
    input            CLK,
    input            CLKx2,
    input            CLKx4,
    output reg [7:0] OUTD,
    input [7:0]      ALU,
    input            nOL,
    output           nAE,
    output [18:0]    RA,
    input [7:0]      RDIN,
    output [7:0]     RDOUT,
    output           nROE,
    output           nRWE,
    input [15:0]     GA,
    input [7:0]      GBUSIN,
    output [7:0]     GBUSOUT,
    input            nGOE,
    input            nGWE,
    output           nACTRL,
    output [1:0]     nADEV,
    output reg       SCK,
    input            MISO,
    output reg       MOSI,
    output reg [1:0] nSS,
    inout [4:3]      XIN );

   reg               SCLK;
   reg               nZPBANK;
   reg [1:0]         BANK;
   wire              nSCTRL;
   
   /* OUT Register (like a 74HC377) */
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   /* IO25 used purely as input.
    * This could also be used to output 
    * a signal for debugging purposes */
   assign XIN = 2'bZ;
   
   /* 74HCT244 always open.
    * Otherwise one could do something like:
    *   always @(negedge CLKx2)  nAE <= !CLK; */
   assign nAE = 1'b0;
   
   /* Ram address bus */
   wire zpswap = !nZPBANK && ( GA[14:7] == 8'b00000001 );
   wire bankenable = GA[15] ^ zpswap;
   wire [3:0] gabank = (bankenable) ? { 2'b00, BANK } : { 4'b0000 };
   assign RA = { gabank, GA[14:0] };

   /* Ram data bus */
   assign RDOUT = GBUSIN;
   
   /* Gigatron bus out */
   wire       portenable;
   assign portenable = SCLK && (GA == 16'h0000);
   assign GBUSOUT = (portenable) ? { BANK, XIN, 3'b000, MISO } : RDIN;
   
   /* Ram control */
   assign nROE = nGOE | portenable;
   assign nRWE = nGWE | !nGOE;
   
   /* Ctrl detection */
   assign nSCTRL = nGOE || nGWE || GA[3:2] == 2'b00;
   assign nACTRL = nGOE || nGWE || GA[3:2] != 2'b00;
   assign nADEV[0] = GA[7:4] == 4'b0000;
   assign nADEV[1] = GA[7:4] == 4'b0001;
   
   /* Ctrl bits */
   always @(negedge CLKx2)
     if (!nSCTRL) 
       begin
          MOSI <= GA[15];
          BANK <= GA[7:6];
          nZPBANK <= GA[5];
          nSS <= GA[3:2];
          SCLK <= GA[0];
          SCK <= GA[0] ^~ GA[4];
       end
   
endmodule 

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */

            
