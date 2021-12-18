
module top(
    input         CLK,
    input         CLKx2,
    input         CLKx4,
    input         nGOE,
    output [7:0]  OUTD,
    input [7:0]   ALU,
    input         nOL,
    inout [7:0]   RAL,
    output [18:8] RAH,
    output        nROE,
    output        nRWE,
    inout [7:0]   RD,
    output        nAE,
    inout [7:0]   GBUS,
    input [15:8]  GAH,
    input         nGWE,
    output        nACTRL,
    output [1:0]  nADEV,
    inout [4:3]   XIN,
    input [2:0]   MISO,
    output        MOSI,
    output        SCK,
    output [1:0]  nSS
);

   /* This toplevel module isolates
      all the programming of inout pins
      where a mistake could potentially
      result in a short. */
      
   wire [18:0]       RA;
   wire [15:0]       GA;
   wire [7:0]        GBUSOUT;
   wire [7:0]        RDOUT;

   /* Ram Address bus
    * This prevents from driving the low address lines
    * from both the CPLD and the 74HCT244 */
   assign RAL = (nAE) ? RA[7:0] : 8'bZ; 
   assign RAH = RA[18:8];
   
   /* Gigatron address bus.
    * The lower half is valid when nAE==0 only. */
   assign GA = { GAH, (nAE) ? 8'bXXXXXXXX : RAL };
   
   /* Gigatron data bus.
    * This prevents from driving it when nGOE=1 */
   assign GBUS = (nGOE) ? 8'bZZZZZZZZ : GBUSOUT;
   
   /* Ram data bus. This prevents from driving it when nROE=1 */
   assign RD = (nROE) ? 8'bZZZZZZZZ : RDOUT;
   
   /* MISO mixing */
   wire              MISOm;
   assign MISOm = (MISO[0] & !nSS[0]) | 
                  (MISO[1] & !nSS[1]) | 
                  (MISO[2] & nSS[0] & nSS[1]);

   /* Invoke main module */
   main themain( 
		 .CLK (CLK),
                 .CLKx2 (CLKx2),
                 .CLKx4 (CLKx4), 
                 .OUTD (OUTD),
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
                 .MISO (MISOm),
                 .MOSI (MOSI),
                 .nSS (nSS),
                 .XIN (XIN) );

endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
