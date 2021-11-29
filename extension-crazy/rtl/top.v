
module top(
    input         CLK,
    input         CLKx2,
    input         CLKx4,
    input         OEINH,
    input         nGOE,
    output [7:0]  OUT,
    input [7:0]   ALU,
    input         nOL,
    inout [7:0]   RAL,
    output [10:0] RAH,
    output        nROE,
    output        nRWE,
    inout [7:0]   RD,
    output        nAE,
    inout [7:0]   GBUS,
    input [7:0]   GAH,
    input         nGWE,
    output        nACTRL,
    output [1:0]  nADEV,
    inout         IO25,
    input [2:0]   MISO,
    output        MOSI,
    output        SCK,
    output [1:0]  nSS);

   /* This toplevel module isolates
      all the programming of inout pins
      where a mistake could potentially
      result in a short. */
      
   wire [18:0]       RA;
   wire [15:0]       GA;
   wire [7:0]        GBUSOUT;
   wire [7:0]        RDOUT;
   wire              MISOmerged;

   /* Ram Address bus
    * This prevents from driving the low address lines
    * from both the CPLD and the 74HCT244 */
   assign RAL = (nAE) ? RA[7:0] : 8'bZ; 
   assign RAH = RA[18:8];
   
   /* Gigatron address bus.
    * The lower half is valid when nAE==0 only. */
   assign GA = { GAH, RAL };
   
   /* Gigatron data bus.
    * This prevents from driving it when nGOE=1 */
   assign GBUS = (nGOE || OEINH) ? 8'bZ : GBUSOUT;
   
   /* Ram data bus. This prevents from driving it when nROE=1 */
   assign RD = (nROE) ? 8'bZ : RDOUT;
   
   /* MISO mixing */
   assign MISOmerged = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   
   main themain( 
			.CLK (CLK),
         .CLKx2 (CLKx2),
         .CLKx4 (CLKx4), 
         .OUT (OUT),
         .ALU (ALU),
         .nOL (nOL),
         .nAE (nAE),
         .RA (RA),
         .RDIN (RD),
         .RDOUT (RDOUT),
         .nROE (nROE),
         .nRWE (nRWE),
         .GA (GA),
         .GBUSIN (GBUS),
         .GBUSOUT (GBUSOUT),
         .nGOE (nGOE),
         .nGWE (nGWE),
         .nACTRL (nACTRL),
         .nADEV (nADEV),
         .SCK (SCK),
         .MISO (MISOmerged),
         .MOSI (MOSI),
         .nSS (nSS),
         .IO25 (IO25) );
   
endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
