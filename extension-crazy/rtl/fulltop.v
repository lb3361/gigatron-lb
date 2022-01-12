

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
   reg [3:0]   NBANKR;
   reg [3:0]   NBANKW;
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

   `define LATE_NAE 1
   
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

   `ifdef MIDDLE_NAE
   /* This does not work, most likely because
    * the CLKx4 signal occasionally rebounds
    * above 0.4v when CLKx4 should be low.
    * Hopefully this gets cured in new board versions
    * by powering the PLL in 3.3v
    * and adding a 22 ohms serial resistor on CLKx4.
    */
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
   (* KEEP = "TRUE" *) wire [3:0] nbank = (nGOE) ? NBANKW : NBANKR;
   (* KEEP = "TRUE" *) wire nbankenable = GAH[15] && nbank != 4'b0000;
   (* PWR_MODE = "STD" *) wire bankenable = GAH[15] ^ (!nZPBANK && RAL[7] && gahz);
   wire [3:0] gbank = (nbankenable) ? nbank : (bankenable) ? { 2'b00, BANK } : 4'b0000;
   assign RAH = { gbank, GAH[14:8] };
   assign RAL = (nAE) ? GA[7:0] : 8'hZZ;

   
   /* Gigatron data */
   wire misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   wire portx = SCLK && !GAH[15] && gahz;
   always @*
     if (! nAE)                 // transparent latch
       casez ( { portx, RAL[7:0] } )
         { 1'b1, 8'h00 } :   GBUSOUT = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
         { 1'b1, 8'hF0 } :   GBUSOUT = { NBANKW[3:0], NBANKR[3:0] };           // bank data
         default:            GBUSOUT = RD[7:0];                                // ram data
       endcase
   assign GBUS = (nGOE) ? 8'hZZ : GBUSOUT;
   
   
   /* Ram data and control */
   /* One could do:
    * 
    * assign nROE = 1'b0;
    * assign nRWE = nGWE || nAE || !nGOE || !nBE;
    * assign RD = (nRWE) ? 8'hZZ : GBUS;
    * 
    * but the following should give better write timings
    */

   always @(negedge CLKx4)
     if (!nBE && !nAE)
       nRWE <= nGWE || !nGOE;
     else
       nRWE <= 1'b1;
   
   always @(negedge CLKx4, posedge nAE)
     if (nAE)
       nROE <= 1'b0;
     else if (!nBE && !nAE)
       nROE <= !nGWE && nGOE;
   
   assign RD = (nROE) ? GBUS : 8'hZZ;
   
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
                    NBANKR[3:0] <= 4'b0;
                    NBANKW[3:0] <= 4'b0;
                 end
            end
          /* Extended ctrl code */
          else
            case (GA[7:4])      /* Device 0xf : set NBANKW/R */
              4'hf : begin
                 NBANKR[3:0] <= GA[11:8];
                 NBANKW[3:0] <= GA[15:12];
              end
            endcase
       end

   /* PWM */
   assign PWM = 1'b0;
   
endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
