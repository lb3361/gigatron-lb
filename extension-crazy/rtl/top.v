
`define WRITE_WITH_NROE_AFTER_NRWE
`define PWMBITS 8
`undef  DISABLE_VIDEO_SNOOP


module top(input            CLK,     // 6.25MHz clock 
           input            CLKx2,   // 12.5MHz clock from PLL
           input            CLKx4,   // 25MHz clock from PLL
           input            nGOE,    // OE signal from SRAM socket
           output reg [7:0] OUTD,    // Video output, latched by 74HCT377 on CLKx2 rising
           input [7:0]      ALU,     // ALU output from OutputReg socket
           input            nOL,     // OL signal from OutputReg socket
           inout [7:0]      RAL,     // Low address from 74LVC244 and 512k ram
           output [18:8]    RAH,     // 512k ram high address bits
           output reg       nROE,    // 512k ram output enable
           output reg       nRWE,    // 512k ram write enable
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
   
   reg                      SCLK;    // ctrlBits: SCLK
   reg                      nZPBANK; // ctrlBits: /ZPBANK
   reg [1:0]                BANK;    // ctrlBits: BANK
   reg [3:0]                NBANK;   // extended bank register
   reg                      NBANKP;  // override normal banking scheme
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
    *                              ____         _______         _______
    *  /BE                             \_______/       \_______/       \
    *                               _______         _______         ____
    *  /AE                         /       \_______/       \_______/    
    *
    *  Cycle                       --VVV-vvvGGGGGGGG-VVV-vvvGGGGGGGG-VVV
    */
   
   reg nBE;
   always @(negedge CLKx4)
     begin
        if (CLKx2)
          nBE <= !CLK;
        nAE <= nBE;
     end
   
   /* ================ Gigatron bank selection */

   (* KEEP = "TRUE" *) wire gahz = GAH[14:8] == 7'h00;
   wire bankenable  = GAH[15] ^ (!nZPBANK && RAL[7] && gahz);
   reg [3:0] gbank;
   always @*
     if (NBANKP && GAH[15])
       gbank = NBANK;           // nbank bank overrides ctrlbits bank
     else if (!bankenable)
       gbank = 4'b0000;         // no banking
     else if (BANK == 2'b00)
       gbank = NBANK;           // nbank applies when bank is 00
     else
       gbank = { 2'b00, BANK }; // normal banking
   
   
   /* ================ Gigatron data bus */
   
   reg [7:0] gbusout;
   wire misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   wire portx = SCLK && !GAH[15] && gahz && RAL[7:0] == 8'h00;
   always @*
     if (! nAE) // transparent latch
       gbusout = (portx) ? { BANK[1:0], XIN[4:3], 3'b000, misox } : RD[7:0];
   assign GBUS = (nGOE) ? 8'hZZ : gbusout;
   
   
   /* ================ SRAM interface 
    *
    * This is tricky because we must ensure
    * that no conflict arises when we commute the 74lvc244.
    * The solution is to ensure that, when nAE rises,
    * both the xc95144 and the 74lvc244 have the same
    * idea of what should be on RAL.
    */
   
   reg [18:0] ra;
   assign RAH = (nAE) ? ra[18:8] : { gbank, GAH[14:8] };
   assign RAL = (nAE) ? ra[7:0] : 8'hZZ;
   always @(posedge CLKx4)
     if (nAE)
       ra <= { VBANK[3:2], VBANK[nBE], VADDR[15:0] };
     else
       ra <= { RAH, RAL };

   /* One could do:
    *   assign nROE = 1'b0;
    *   assign nRWE = nGWE || nAE || !nGOE || !nBE;
    *   assign RD = (nRWE) ? 8'hZZ : GBUS;
    * but the following should give better write timings
    */

   always @(negedge CLKx4)
     if (!nBE && !nAE)
       nRWE <= nGWE || !nGOE;
     else
       nRWE <= 1'b1;

`ifdef WRITE_WITH_NROE_NRWE_TOGETHER
   always @(negedge CLKx4, posedge nAE)
     if (nAE)
       nROE <= 1'b0;
     else if (!nBE && !nAE)
       nROE <= !nGWE && nGOE;
`endif
`ifdef WRITE_WITH_NROE_AFTER_NRWE
   always @(posedge CLKx4, posedge nAE)
     if (nAE)
       nROE <= 1'b0;
     else if (nBE && !nAE)
       nROE <= !nRWE;
`endif
   assign RD = (nROE) ? GBUS : 8'hZZ;

   
   
   /* ================ Scanline detection */ 
   
   reg        snoop;
   wire       snoopchg = !nGOE && !(gahz && !GAH[15]);
   wire [7:0] nvaddr = VADDR[7:0] + 8'h01;
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
       OUTD <= { sync[1:0], (snoop) ? RD[5:0] : 6'h00 };
     else if (!nBE && nAE)
       outnxt[5:0] <= (snoop) ? RD[5:0] : 6'h00;
     else if (nBE && !nAE)
       OUTD[5:0] <= outnxt[5:0];
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
        pwmcnt <= pwmcnt + 6'h01;
        PWM <= (rpwmcnt < PWMD);
     end
   
   
   /* ================ Ctrl codes */
   
   wire nCTRL = nAE || nGOE || nGWE;

   assign nACTRL =   nCTRL || RAL[3:0] != 4'b0000;
   assign nADEV[0] = nAE   || RAL[7:4] == 4'b0000;
   assign nADEV[1] = nAE   || RAL[7:4] == 4'b0001;

   always @(posedge CLKx4)
     if (!nAE && nBE)
       begin
          if (! nCTRL)
            begin
               casez (RAL[3:0])
                 4'b0000:       // extended ctrl codes
                   begin
                      case (RAL[7:4])
                        4'hf : 
                          begin // dev15: set new bank register
                             NBANK <= GAH[15:12];
                             NBANKP <= GAH[11];
                          end
                        4'he : 
                          begin // dev14: set video bank
                             VBANK[3:0] <= GAH[11:8];
                          end
                        4'hd : 
                          begin // dev13: set PWM threshold
                             PWMD <= GAH[15:16-`PWMBITS];
                          end
                      endcase
                   end
                 default:       // normal ctrl codes
                   begin
                      MOSI <= GAH[15];
                      BANK <= RAL[7:6];
                      nZPBANK <= RAL[5];
                      nSS <= RAL[3:2];
                      SCLK <= RAL[0];
                      SCK <= RAL[0] ^~ RAL[4];
                      if (RAL[1:0] == 2'b11)
                        begin   // reset
                           NBANK <= 4'b0;
                           NBANKP <= 1'b0;
                           VBANK <= 4'b0;
                           PWMD  <= 8'h00;
                        end
                   end
               endcase // casez (RAL[3:0])
            end // if (! nCTRL)
       end // if (!nAE && nBE)

initial
  begin
     NBANK = 4'b0;
     NBANKP = 1'b0;
     VBANK = 4'b0;
     PWMD  = 8'h00;
  end

   
endmodule


/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
