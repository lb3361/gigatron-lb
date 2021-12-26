

/* Goal: Achieving parity with the V7 GAL-based boards.
   Bonus: Support for 512KB banking. */

module top((* BUFG = "CLK" *) input CLK,
           (* BUFG = "CLK"  *) input CLKx2,
           (* BUFG = "CLK"  *) input CLKx4,
           (* BUFG = "OE" *) input nGOE,
           (* _ *) output reg [7:0] OUTD, 
           (* _ *) input [7:0] ALU,
           (* _ *) input nOL,
           (* _ *) inout [7:0] RAL,
           (* _ *) output [18:8] RAH,
           (* BUFG = "OE" *) output nROE,
           (* _ *) output nRWE,
           (* _ *) inout [7:0] RD,
           (* _ *) (* BUFG = "OE" *) output reg nAE,
           (* PWR_MODE = "LOW" *) inout [7:0] GBUS,
           (* _ *) input [15:8] GAH,
           (* _ *) input nGWE,
           (* PWR_MODE = "LOW" *) output nACTRL,
           (* PWR_MODE = "LOW" *) output [1:0] nADEV,
           (* PWR_MODE = "LOW" *) input [4:3] XIN,
           (* PWR_MODE = "LOW" *) input [2:0] MISO,
           (* PWR_MODE = "LOW" *) output reg MOSI,
           (* PWR_MODE = "LOW" *) output reg SCK,
           (* PWR_MODE = "LOW" *) output reg [1:0] nSS 
           );
   
   (* PWR_MODE = "LOW" *) reg         SCLK;
   (* PWR_MODE = "LOW" *) reg         nZPBANK;
   (* PWR_MODE = "LOW" *) reg [1:0]   BANK;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0R;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0W;
   (* PWR_MODE = "LOW" *) reg [7:0]   GBUSOUT;
   (* _ *) reg [15:0] GA;
   (* _ *) reg [18:0] RA;


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
    *                              ____         _______         _______
    *  /AE                             \_______/       \_______/       \
    *                                  ^ downedge(CLKX4) & CLKx2 & CLK
    *                                          ^ downedge(CLKx4) & CLKx2 & /CLK
    */

   always @(negedge CLKx4)
     begin
        if (CLKx2)
          nAE <= !CLK;
     end

   /* Gigatron addresses */
   always @*
     begin
        GA[15:8] = GAH[15:8];
        if (!nAE)               // transparent latch
          GA[7:0] = RAL[7:0];
     end
   
   /* Ram addresses */
   (* PWR_MODE = "LOW" *) wire zpbank;
   (* PWR_MODE = "STD" *) wire bankenable;
   assign zpbank = !nZPBANK && GAH[14:8] == 7'h00;
   assign bankenable = GA[15] ^ (zpbank && GA[7]);
   always @*
     casez ( { bankenable, BANK[1:0], nGOE } )
       4'b0??? :  RA = { 4'b0000, GA[14:0] };            // no banking
       4'b1000 :  RA = { BANK0R[3:0], GA[14:0] };        // bank0, reading
       4'b1001 :  RA = { BANK0W[3:0], GA[14:0] };        // bank0, maybe writing
       default :  RA = { 2'b00, BANK[1:0], GA[14:0] };   // bank123
     endcase 
   assign RAL = (nAE) ? RA[7:0] : 8'bZZZZZZZZ;
   assign RAH = RA[18:8];
   
   /* Gigatron data */
   (* PWR_MODE = "LOW" *) wire misox;
   (* PWR_MODE = "LOW" *) wire portx;
   assign misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   assign portx = SCLK && GAH[15:8] == 8'h00;
   always @*
     if (! nAE)                 // transparent latch
       casez ( { portx, RAL[7:0] } )
         { 1'b1, 8'h00 } :   GBUSOUT = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
         { 1'b1, 8'hF0 } :   GBUSOUT = { BANK0W[3:0], BANK0R[3:0] };           // bank data
         default:            GBUSOUT = RD[7:0];                                // ram data
       endcase
   assign GBUS = (nGOE) ? 8'bZZZZZZZZ : GBUSOUT;
   

   /* Ram data and control */
   assign nROE = nGOE;
   assign nRWE = nGWE || nAE || !nGOE;
   assign RD = (nROE) ? GBUS : 8'bZZZZZZZZ;

   /* Ctrl detection */
   wire nCTRL;
   assign nCTRL = nGOE || nGWE;
   assign nACTRL = nCTRL || GA[3:2] != 2'b00;
   assign nADEV[0] = (GA[7:4] == 4'b0000);
   assign nADEV[1] = (GA[7:4] == 4'b0001);
   
   /* Ctrl bits */
   always @(posedge nCTRL)
     begin
        /* Reset */
        if (GA == 8'h7F)
          begin
             BANK0R <= 4'b0;
             BANK0W <= 4'b0;
          end
        /* Normal ctrl code */         
        if (GA[3:2] != 2'b00)
          begin
             MOSI <= GA[15];
             BANK <= GA[7:6];
             nZPBANK <= GA[5];
             nSS <= GA[3:2];
             SCLK <= GA[0];
             SCK <= GA[0] ^~ GA[4];
          end
        /* Extended ctrl code */
        if (! nACTRL)
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
