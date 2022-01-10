

/* Goal: Achieving parity with the V7 GAL-based boards.
   Bonus: Support for 512KB banking. */

module top(input            CLK,
           input            CLKx2,
           input            CLKx4,
           input            nGOE,
           output reg [7:0] OUTD, 
           input [7:0]      ALU,
           input            nOL,
           inout [7:0]      RAL,
           output [18:8]    RAH,
           output reg       nROE,
           output reg       nRWE,
           inout [7:0]      RD,
           output reg       nAE,
           inout [7:0]      GBUS,
           input [15:8]     GAH,
           input            nGWE,
           output           nACTRL,
           output [1:0]     nADEV,
           input [4:3]      XIN,
           input [2:0]      MISO,
           output reg       MOSI,
           output reg       SCK,
           output reg [1:0] nSS,
           output           PWM
           );
   
   reg         SCLK;
   reg         nZPBANK;
   reg [1:0]   BANK;
   reg [3:0]   BANK0R;
   reg [3:0]   BANK0W;
   reg [7:0]   GBUSOUT;
   reg [15:0]  GA;
   reg         nBE;
   
   /* Output register */
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   /*  TIMINGS
    *                              110000000000111111000000000011111100
    *                              450123456789012345012345678901234501
    *                               _____           _____           ___
    *  Gigatron clock              /     \_________/     \_________/
    *  (also /WE)
    *                                 _____           _____           __
    *  CLK                         __/     \_________/     \_________/
    *                                 ___     ___     ___     ___     __
    *  CLKx2                       __/   \___/   \___/   \___/   \___/
    *                                 _   _   _   _   _   _   _   _   _
    *  CLKx4                       \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
    *                              ____             ___             ____
    *  /AE (LONG_NAE)                  \___________/   \___________/    
    *                              ____         _______         _______
    *  /AE (EARLY_NAE)                 \_______/       \_______/       \
    *                              ______         _______         ______
    *  /AE (MIDDLE_NAE)                  \_______/       \_______/       
    *                              ________         _______         ____
    *  /AE (LATE_NAE)                      \_______/       \_______/       
    * 
    *  /BE precedes /AE by one CLKx4 cycle.
    */

   `define LONG_NAE 1
   
   `ifdef LONG_NAE
   always @(negedge CLKx4)
     if (CLKx2 && !CLK)
       nBE <= 1'b1;
     else
       nBE <= 1'b0;
   always @(negedge CLKx4)
     nAE <= nBE;
   `endif

   `ifdef EARLY_NAE
   always @(negedge CLKx4)
     if (CLKx2)
       nAE <= !CLK;
   always @(negedge CLKx4)
     nBE <= !nAE;
   `endif

   `ifdef MIDDLE_NAE  // this one does not work for some reason!
   always @(posedge CLKx4)
     if (CLKx2)
       nAE <= !CLK;
   always @(posedge CLKx4)
     nBE <= !nAE;
   `endif
   
   `ifdef LATE_NAE
   always @(negedge CLKx4)
     if (CLKx2)
       nBE <= !CLK;
   always @(negedge CLKx4)
     nAE <= nBE;
   `endif

   `ifdef MIDDLE_NAE
   wire CLOCK = CLKx4;
   `else
   wire CLOCK = !CLKx4;
   `endif
  
   `ifdef LONG_NAE
   wire nBEraising = !nAE && !nBE && CLKx2;
   `else
   wire nBEraising = !nAE && !nBE;
   `endif
   
   /* Gigatron addresses */
   always @*
     begin
        GA[15:8] = GAH[15:8];
        if (!nAE)               // transparent latch
          GA[7:0] = RAL[7:0];
     end
   
   /* Ram addresses */
   (* KEEP = "TRUE" *) wire gahz = (GAH[14:8] == 7'h00);
   wire bankenable = GAH[15] ^ (!nZPBANK && RAL[7] && gahz);
   reg [3:0] gbank;
   always @*
     casez ( { bankenable, BANK[1:0], nGOE } )
       4'b0??? :  gbank = { 4'b0000 };            // no banking
       4'b1000 :  gbank = { BANK0R[3:0] };        // bank0, reading
       4'b1001 :  gbank = { BANK0W[3:0] };        // bank0, maybe writing
       default :  gbank = { 2'b00, BANK[1:0] };   // bank123
     endcase 
   assign RAL = (nAE) ? GA[7:0] : 8'hZZ;
   assign RAH = { gbank, GAH[14:8] };
   
   /* Gigatron data */
   wire misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   wire portx = SCLK && !GAH[15] && gahz;
   always @*
     if (! nAE)                 // transparent latch
       casez ( { portx, RAL[7:0] } )
         { 1'b1, 8'h00 } :   GBUSOUT = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
         { 1'b1, 8'hF0 } :   GBUSOUT = { BANK0W[3:0], BANK0R[3:0] };           // bank data
         default:            GBUSOUT = RD[7:0];                                // ram data
       endcase
   assign GBUS = (nGOE) ? 8'hZZ : GBUSOUT;
   
   
   /* Ram data and control */
   always @(posedge CLOCK, posedge nAE)
     if (nAE)
       nROE <= 1'b0;
     else if (nBEraising && !nGWE && nGOE)
       nROE <= 1'b1;

   assign RD = (nROE) ? GBUS : 8'hZZ;
   
   wire nRWEreset = CLOCK & nROE;
   always @(posedge CLOCK, posedge nRWEreset)
     if (nRWEreset)
       nRWE <= 1'b0;
     else
       nRWE <= 1'b1;
   
   
   /* Ctrl detection */
   wire nCTRL;
   assign nCTRL = nGOE || nGWE;
   assign nACTRL = nCTRL || GA[3:2] != 2'b00;
   assign nADEV[0] = (GA[7:4] == 4'b0000);
   assign nADEV[1] = (GA[7:4] == 4'b0001);
   
   /* Ctrl bits */
   always @(negedge CLKx2)
     if (!CLK && !nCTRL)
       begin
          /* Normal ctrl code */         
          if (GA[3:2] != 2'b00)
            begin
               MOSI <= GA[15];
               BANK <= GA[7:6];
               nZPBANK <= GA[5];
               nSS <= GA[3:2];
               SCLK <= GA[0];
               SCK <= GA[0] ^~ GA[4];
               /* System reset */
               if (GA[1:0] == 2'b11)
                 begin
                    BANK0R[3:0] <= 4'b0;
                    BANK0W[3:0] <= 4'b0;
                 end
            end
          /* Extended ctrl code */
          else
            case (GA[7:4])      /* Device 0xf : set BANK0W/R */
              4'hf : begin
                 BANK0R[3:0] <= GA[11:8];
                 BANK0W[3:0] <= GA[15:12];
              end
            endcase
       end

   /* PWM */
   assign PWM = 1'b0;
   
endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
