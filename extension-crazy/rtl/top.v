

module top(input            CLK,
           input            CLKx2,
           input            CLKx4,
           input            nGOE,
           output reg [7:0] OUTD, 
           input [7:0]      ALU,
           input            nOL,
           inout [7:0]      RAL,
           output [18:8]    RAH,
           output           nROE,
           output           nRWE,
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
           output reg       PWM
           );
   
   (* PWR_MODE = "LOW" *) reg         SCLK;
   (* PWR_MODE = "LOW" *) reg         nZPBANK;
   (* PWR_MODE = "LOW" *) reg [1:0]   BANK;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0R;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0W;
   (* PWR_MODE = "LOW" *) reg [5:0]   PWMD;
   (* PWR_MODE = "LOW" *) reg [3:0]   VBANK;
   (* PWR_MODE = "STD" *) reg [15:0]  VADDR;

   /* ================ Clocks
    *
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
    *                              ____         _______         _______
    *  /BE                             \_______/       \_______/       \
    *                               _______         _______         ____
    *  /AE                         /       \_______/       \_______/    
    *
    *  Cycle                       --VVV-vvvGGGGGGGG-VVV-vvvGGGGGGGG-VVV
    */
   
   (* PWR_MODE = "STD" *) reg nBE;
   always @(negedge CLKx4)
     begin
        if (CLKx2)
          nBE <= !CLK;
        nAE <= nBE;
     end
   
   /* ================ Gigatron data bus */
   
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) wire gahz;
   assign gahz = (GAH[14:8] == 7'h00);
   (* PWR_MODE = "LOW" *) wire portx;
   assign portx = SCLK && !GAH[15] && gahz;
   (* PWR_MODE = "LOW" *) wire misox;
   assign misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   (* PWR_MODE = "LOW" *) reg [7:0] gbusout;
   always @*
     if (! nAE)                 // transparent latch
       casez ( { portx, RAL[7:0] } )
         { 1'b1, 8'h00 } :   gbusout = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
         { 1'b1, 8'hF0 } :   gbusout = { BANK0W[3:0], BANK0R[3:0] };           // bank data
         default:            gbusout = RD[7:0];                                // ram data
       endcase
   assign GBUS = (nGOE) ? 8'hZZ : gbusout;
   
   
   /* ================ Gigatron bank selection */
   
   (* PWR_MODE = "STD" *) wire bankenable;
   assign bankenable = GAH[15] ^ (!nZPBANK && RAL[7] && gahz);
   (* PWR_MODE = "STD" *) (* KEEP = "TRUE" *) reg [3:0] gbank;
   always @*
     casez ( { bankenable, BANK[1:0], nGOE } )
       4'b0??? :  gbank = { 4'b0000 };            // no banking
       4'b1000 :  gbank = { BANK0R[3:0] };        // bank0, reading
       4'b1001 :  gbank = { BANK0W[3:0] };        // bank0, maybe writing
       default :  gbank = { 2'b00, BANK[1:0] };   // bank123
     endcase 
   
   
   /* ================ SRAM interface 
    *
    * This is very tricky because we must ensure
    * that no conflict arises when we commute the 74lvc244.
    * The solution is to ensure that, when nAE rises,
    * both the xc95144 and the 74lvc244 have the same
    * idea of what should be on RAL.
    */

   assign nROE = 1'b0;
   assign nRWE = nGWE || nAE || !nGOE;
   assign RD = (nRWE) ? 8'hZZ : GBUS;
   
   (* PWR_MODE = "STD" *) reg [18:0] ra;
   always @(posedge CLKx4)
     if (nAE)
       ra <= { VBANK[3:2], VBANK[nBE], VADDR[15:0] };
     else
       ra <= { gbank, GAH[14:8], RAL[7:0] };
   assign RAH = (nAE) ? ra[18:8] : { gbank, GAH[14:8] };
   assign RAL = (nAE) ? ra[7:0] : 8'hZZ;

   
   /* ================ Scanline detection */ 
   
   (* PWR_MODE = "LOW" *) reg snoop;
   (* PWR_MODE = "LOW" *) wire snoopchg = !nGOE && !(gahz && !GAH[15]);
   (* PWR_MODE = "LOW" *) wire [7:0] nvaddr = VADDR[7:0] + 8'h01;
   always @(negedge CLKx2)
     if (! nAE)
       begin
          if (! nOL)
            // Snooping starts when an OUT instruction reads memory
            // outside page zero and stop on any other OUT opcode.
            snoop <=  snoopchg;
          if (! nOL && ! nGOE)
            // Reset snooping address when an OUT reads memory
            VADDR <= { GAH, RAL };
          else
            // Otherwise increment address to next pixel
            VADDR[7:0] <= nvaddr;
       end
   
   
   /* ================ Output register */

   reg [5:0] outnxt;
   always @(posedge CLK)
     if (! nOL)
       OUTD[7:6] <= ALU[7:6];
   always @(negedge CLKx4)
     if (nBE && nAE)
       OUTD[5:0] <= (snoop) ? RD[5:0] : 6'h00;
     else if (!nBE && nAE)
       outnxt[5:0] <= (snoop) ? RD[5:0] : 6'h00;
     else if (nBE && !nAE)
       OUTD[5:0] <= outnxt[5:0];

   
   /* ================ Ctrl codes */
   
   (* PWR_MODE = "LOW" *) wire nCTRL = nAE || nGOE || nGWE;
   assign nACTRL =   nCTRL || RAL[3:2] != 2'b00;
   assign nADEV[0] = nAE   || RAL[7:4] == 4'b0000;
   assign nADEV[1] = nAE   || RAL[7:4] == 4'b0001;
   always @(posedge nCTRL)
     begin
        /* Normal ctrl code */         
        if (RAL[3:2] != 2'b00)
          begin
             MOSI <= GAH[15];
             BANK <= RAL[7:6];
             nZPBANK <= RAL[5];
             nSS <= RAL[3:2];
             SCLK <= RAL[0];
             SCK <= RAL[0] ^~ RAL[4];
             if (RAL[1:0] == 2'b11) // System reset
               begin
                  BANK0R[3:0] <= 4'b0;
                  BANK0W[3:0] <= 4'b0;
                  VBANK[3:0] <= 4'b0;
                  PWMD[5:0] <= 6'h00;
               end
          end
        /* Extended ctrl code */
        else
          case (RAL[7:4])
            4'hf : begin        // Device 0xf : extended banking
               BANK0R[3:0] <= GAH[11:8];
               BANK0W[3:0] <= GAH[15:12];
            end
            4'he : begin        // Device 0xe : set video bank
               VBANK[3:0] <= GAH[11:8];
            end
            4'hd : begin        // Device 0xd : PWM
               PWMD[5:0] <= GAH[15:10];
            end
          endcase
     end


   /* ======== Bit reversed PWM 
    *
    * Reversed bit PWM moves noise into higher frequencies
    * that are more easily filtered.
    */
   
   (* PWR_MODE = "LOW" *) reg [5:0] pwmcnt;
   always @(posedge CLK)
     pwmcnt <= pwmcnt + 6'h01;
   wire [5:0] rpwmcnt = { pwmcnt[0], pwmcnt[1], pwmcnt[2], pwmcnt[3], pwmcnt[4], pwmcnt[5] };
   always @(posedge CLK)
     PWM <= (rpwmcnt < PWMD);

endmodule


/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
