
module main(
    input             CLK,
    input             CLKx2,
    input             CLKx4,
    output reg [7:0]  OUTD,
    input [7:0]       ALU,
    input             nOL,
    output            nAE,
    output reg [18:0] RA,
    input [7:0]       RDIN,
    output [7:0]      RDOUT,
    output            nROE,
    output            nRWE,
    input [15:0]      GA,
    input [7:0]       GBUSIN,
    output reg [7:0]  GBUSOUT,
    input             nGOE,
    input             nGWE,
    output            nACTRL,
    output [1:0]      nADEV,
    output reg        SCK,
    input             MISO,
    output reg        MOSI,
    output reg [1:0]  nSS,
    inout [4:3]       XIN );

   reg                SCLK;
   reg                nZPBANK;
   reg [1:0]          BANK;
   reg [3:0]          BANK0R;
   reg [3:0]          BANK0W;
   
   /* OUT Register (like a 74HC377) */
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   /* XIN used purely as input.
    * This could also be used to output 
    * a signal for debugging purposes */
   assign XIN = 2'bZ;
   
   /* 74HCT244 always open.
    * Otherwise one could do something like:
    *   always @(negedge CLKx2)  nAE <= !CLK; */
   assign nAE = 1'b0;
   
   /* Ram address bus */
   /* Ram address bus */
   wire bankenable = GA[15] ^~ (!nZPBANK && GA[14:7] == 8'h01);
   always @*
     casez ( { bankenable, BANK, nGOE } )
       4'b0??? :  RA = { 4'b0000, GA[14:0] };       // no banking
       4'b1000 :  RA = { BANK0R, GA[14:0] };        // bank0, reading
       4'b1001 :  RA = { BANK0W, GA[14:0] };        // bank0, maybe writing
       default :  RA = { 2'b00, BANK, GA[14:0] };   // bank123
     endcase

   /* Ram data bus */
   assign RDOUT = GBUSIN;
   
   /* Gigatron bus out */
   always @*
     casez ( { SCLK, GA } )
       { 1'b1, 16'h0000 } :   GBUSOUT = { BANK, XIN, 3'b000, MISO }; // spi data
       { 1'b1, 16'h0080 } :   GBUSOUT = { BANK0W, BANK0R };          // bank data
       default:               GBUSOUT = RDIN;
     endcase
   
   /* Ram control */
   assign nROE = nGOE;
   assign nRWE = nGWE | !nGOE;

   /* Ctrl detection */
   wire nCTRL = nGOE || nGWE;
   assign nACTRL = nCTRL || GA[3:2] != 2'b00;
   assign nADEV[0] = GA[7:4] == 4'b0000;
   assign nADEV[1] = GA[7:4] == 4'b0001;
   
   /* Ctrl bits */
   always @(negedge CLKx2)
     begin
        /* Reset */
        if (!nCTRL && GA[1:0] == 2'b11)
          begin
             BANK0R <= 4'b0;
             BANK0W <= 4'b0;
          end
        /* Normal ctrl code */         
        if (!nCTRL && GA[3:2] != 2'b00)
          begin
             MOSI <= GA[15];
             BANK <= GA[7:6];
             nZPBANK <= GA[5];
             nSS <= GA[3:2];
             SCLK <= GA[0];
             SCK <= GA[0] ^~ GA[4];
          end
        /* Extended ctrl code */
        if (!nACTRL)
          case (GA[7:4])      /* Device 0xf : set BANK0W/R */
            4'hf : begin
               BANK0R <= GA[11:8];
               BANK0W <= GA[15:12];
            end
          endcase
     end
endmodule 

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */

            
