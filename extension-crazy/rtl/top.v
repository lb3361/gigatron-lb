
`define PWMBITS 8
`undef  DISABLE_VIDEO_SNOOP

/* verilator lint_off UNUSEDSIGNAL */ /* XIN, ALU */
/* verilator lint_off SYNCASYNCNET */ /* nAE */

module top(input            CLK,     // 6.25MHz clock
           input            CLKx2,   // 12.5MHz clock from PLL
           input            CLKx4,   // 25MHz clock from PLL
           input            nGOE,    // OE signal from SRAM socket
           output reg [7:0] OUTD,    // Video output, latched by 74HCT377 on CLKx2 rising
           input [7:0]      ALU,     // ALU output from OutputReg socket
           input            nOL,     // OL signal from OutputReg socket
           inout [7:0]      RAL,     // Low address from 74LVC244 and 512k ram
           output [18:8]    RAH,     // 512k ram high address bits
           output wire      nROE,    // 512k ram output enable
           output wire      nRWE,    // 512k ram write enable
           inout [7:0]      RD,      // 512k ram data lines
           output reg       nAE,     // Active low enable for 74LVC244
           inout [7:0]      GBUS,    // Gigatron data bus from SRAM socket
           input [15:8]     GAH,     // Gigatron high address bits
           input            nGWE,    // WE signal from SRAM socket
           output           nACTRL,  // Aux device control for expansion header
           output [1:0]     nADEV,   // Aux device select for expansion header
           input [4:3]      XIN,     // From expansion header
           input [2:0]      MISO,    // MISO from SPI0, SPI1, expansion header
           output reg       MOSI,    // Common MOSI line
           output reg       SCK,     // SPI clock
           output reg [1:0] nSS,     // SPI select for SPI0 and SPI1
           output reg       PWM      // pulse densite modulation for audio
           );

   reg [3:0]                BANK;    // ctrlBits: BANK
   reg [3:0]                BANK0;   // bank zero override (set with ctrl code X0F0)
   reg [3:0]                VBANK;   // video bank
   reg [15:0]               VADDR;   // video snoop address
   reg [`PWMBITS-1:0]       PWMD;    // pwm threshold


   /* ================ clocks
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
    *                                       _______         _______
    *  /BE                         \_______/       \_______/       \____
    *                              ____         _______         ________
    *  /AE                             \_______/       \_______/
    *
    *  Cycle                       V-vvvGGGGGGGG-VVV-vvvGGGGGGGG-VVV-vvv
    */

   reg nBE;
   always @(negedge CLKx4)
     begin
        if (CLKx2)
          nAE <= !CLK;
        nBE <= !nAE;
     end


   /* ================ Things we can compute early */

   (* KEEP = "TRUE" *) wire [3:0] abank = (! GAH[15]) ? 4'h0 : (| BANK) ? BANK : BANK0;

   (* KEEP = "TRUE" *) wire gah15to8 = (| GAH[15:8]);

   (* KEEP = "TRUE" *) wire misox = ( (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) |
                                      (MISO[2] & nSS[0] & nSS[1]) );


   /* ================ Gigatron data bus */

   (* KEEP = "TRUE" *) reg [7:0] gbusout;

   always @(*) // comb
     case({ nAE, SCK, gah15to8, RAL[7:0] })
       11'b010_00000000 : gbusout = { BANK[1:0], XIN[4:3], 3'b000, misox };
       11'b010_10000000 : gbusout = { BANK[1:0], ~BANK[3:2], nSS[1:0], 2'b00 };
       default          : gbusout = { RD[7:0] };
     endcase

   reg [7:0] gbuslatch;
   always @(nAE or gbusout) // latch
     if (! nAE)
       gbuslatch <= gbusout;

   assign GBUS = (nGOE) ? 8'hZZ : gbuslatch;


   /* ================ SRAM interface
    *
    * This is tricky because we must ensure
    * that no conflict arises when we commute the 74lvc244.
    * The solution is to ensure that, when nAE rises,
    * both the xc95144 and the 74lvc244 have the same
    * idea of what should be on RAL.
    */

   reg [18:0] ra;
   assign RAH = (nAE) ? ra[18:8] : { abank, GAH[14:8] };
   assign RAL = (nAE) ? ra[7:0] : 8'hZZ;
   always @(posedge CLKx4)
     if (nAE)
       ra <= { VBANK[3:2], VBANK[{1'b0,nBE}], VADDR[15:0] };
     else
       ra <= { RAH, RAL };

   /* 
    * The gigatron drives the ram when nAE is low. 
    */

   assign nROE = nGOE && !nAE; //1'b0;
   assign nRWE = nGWE || nAE || !nGOE || !nBE;
   assign RD = (nRWE) ? 8'hZZ : GBUS;



   /* ================ Scanline detection */

   reg snoop;

   always @(posedge CLKx2)
     if (! nAE)
       begin
          if (! nOL)
            // Snooping starts when an OUT instruction reads memory
            // outside page zero and stops on any other OUT opcode.
            snoop <= (! nGOE) && gah15to8;
          if (! nOL && ! nGOE)
            // Reset snooping address whenever an OUT reads memory
            VADDR <= { GAH, RAL };
          else
            // Otherwise increment address to next pixel
            VADDR[7:0] <= VADDR[7:0] + 8'h01;
       end


   /* ================ Output register */

`ifdef DISABLE_VIDEO_SNOOP
   always @(posedge CLK)
     if (! nOL)
       OUTD <= ALU;
`else
   reg [1:0] sync;
   reg [5:0] outnxt;
   always @(posedge CLK)
     if (! nOL)
       sync <= ALU[7:6];
   always @(negedge CLKx4)
     if (nBE && nAE)
       begin
          outnxt[5:0] <= (snoop) ? RD[5:0] : 6'h00;
          OUTD[5:0] <= outnxt[5:0];
       end
     else if (!nBE && nAE)
       begin
          outnxt[5:0] <= (snoop) ? RD[5:0] : 6'h00;
          OUTD <= { sync[1:0], outnxt[5:0] };
       end
`endif


   /* ======== Bit reversed PWM
    * Reversed bit PWM moves noise into higher frequencies
    * that are more easily filtered.
    */

   reg [`PWMBITS-1:0]  pwmcnt;
   wire [`PWMBITS-1:0] rpwmcnt;
   genvar k;
   generate for (k=0; k<`PWMBITS; k=k+1)
     begin : rpwmcnt_loop
        assign rpwmcnt[k] = pwmcnt[`PWMBITS-1-k];
     end
   endgenerate
   always @(posedge CLK)
     begin
        pwmcnt <= pwmcnt + `PWMBITS'h01;
        PWM <= (rpwmcnt < PWMD);
     end


   /* ================ Ctrl codes */

   wire nCTRL = nAE || nGOE || nGWE;

   assign nACTRL =   nCTRL || RAL[3:0] != 4'b0000;
   assign nADEV[0] = nAE   || RAL[7:4] == 4'b0000;
   assign nADEV[1] = nAE   || RAL[7:4] == 4'b0001;

   always @(posedge CLKx4)
     if (!nAE && nBE && !nCTRL)
       begin
          SCK <= RAL[0];
          if (| RAL[3:0])       // normal ctrl codes
            begin
               MOSI <= GAH[15];
               BANK[1:0] <= RAL[7:6];
               BANK[3:2] <= ~RAL[5:4];
               nSS <= RAL[3:2];
               if (& RAL[1:0])  // reset
                 begin
                    BANK0 <= 4'b0000;
                    VBANK <= 4'b0000;
                    PWMD  <= 8'h00;
                 end
            end
          else                  // extended ctrl codes
              begin
                 case (RAL[7:4])
                   4'hf :
                     begin // dev15: set bank
                        if (!GAH[11])
                          begin
                             BANK0 <= GAH[15:12]; // set bank0 override
                          end
                        else
                          begin
                             BANK <= GAH[15:12];  // set bank
                             BANK0 <= 4'b0000;    // reset bank0 override
                          end
                     end
                   4'he :
                     begin // dev14: set video bank
                        VBANK[3:0] <= GAH[11:8];
                     end
                   4'hd :
                     begin // dev13: set PWM threshold
                        PWMD <= GAH[15:16-`PWMBITS];
                     end
                   default :
                     begin
                     end
                 endcase
              end
       end

initial
  begin
     BANK = 4'b0000;
     BANK0 = 4'b0000;
     VBANK = 4'b0000;
     PWMD  = 8'h00;
  end


endmodule


/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
