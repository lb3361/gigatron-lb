

module top(input CLK,
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
           output reg [1:0] nSS 
           );
   
   (* PWR_MODE = "LOW" *) reg         SCLK;
   (* PWR_MODE = "LOW" *) reg         nZPBANK;
   (* PWR_MODE = "LOW" *) reg [1:0]   BANK;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0R;
   (* PWR_MODE = "LOW" *) reg [3:0]   BANK0W;
   (* PWR_MODE = "LOW" *) reg [4:0]   VBANK;
   (* PWR_MODE = "LOW" *) reg [15:0]  VADDR;
   (* PWR_MODE = "STD" *) reg [15:0]  GA;
   (* PWR_MODE = "STD" *) reg         nBE;

   /*  Clocks
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
    *                                   ___________     ___________     
    *  /BE                         \___/           \___/           \___/
    *                                              ^ downedge(CLKx4) & /CLKx2 & /AE
    */
   always @(negedge CLKx4)
     begin
        if (CLKx2)
          nAE <= !CLK;
        nBE <= (CLKx2 || !nAE);
     end

   /* Gigatron address bus */
   always @*
     begin
        GA[15:8] = GAH[15:8];
        if (!nAE)               // transparent latch
          GA[7:0] = RAL[7:0];
     end
   
   /* Gigatron data bus */
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) wire misox;
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) wire gahz;
   (* PWR_MODE = "LOW" *) reg [7:0] gbusout;
   (* PWR_MODE = "LOW" *) wire portx;
   assign misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   assign gahz = (GAH[14:8] == 7'h00);
   assign portx = SCLK && !GAH[15] && gahz;
   always @*
     if (! nAE)                 // transparent latch
       casez ( { portx, RAL[7:0] } )
         { 1'b1, 8'h00 } :   gbusout = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
         { 1'b1, 8'hF0 } :   gbusout = { BANK0W[3:0], BANK0R[3:0] };           // bank data
         default:            gbusout = RD[7:0];                                // ram data
       endcase
   assign GBUS = (nGOE) ? 8'bZZZZZZZZ : gbusout;
   
   /* Ram signals */
   (* PWR_MODE = "LOW" *) wire [18:8] rahv;
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) reg [18:8] rahg;
   wire bankenable = GAH[15] ^ (!nZPBANK && GA[7] && gahz);
   always @*
     casez ( { bankenable, BANK[1:0], nGOE } )
       4'b0??? :  rahg = { 4'b0000, GAH[14:8] };            // no banking
       4'b1000 :  rahg = { BANK0R[3:0], GAH[14:8] };        // bank0, reading
       4'b1001 :  rahg = { BANK0W[3:0], GAH[14:8] };        // bank0, writing
       default :  rahg = { 2'b00, BANK[1:0], GAH[14:8] };   // bank123
     endcase 
   assign rahv = { VBANK[3:1], VADDR[15:8] };
   assign RAL = (nAE) ? GA[7:0] : 8'bZZZZZZZZ;  // should be: (nAE) ? VADDR[7:0] : 8'bZZZZZZZZ;
   assign RAH = rahg[18:8];                     // should be: (nAE) ? rahv[18:8] : rahg[18:8];
   assign nROE = nGOE && !nAE;
   assign nRWE = nGWE || nAE || !nGOE;
   assign RD = (nROE) ? GBUS : 8'bZZZZZZZZ;
   
   /* Scanline detection */
   (* PWR_MODE = "LOW" *) reg snoop;
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) wire snoopchg = !nGOE && !(gahz && !GAH[15]);
   (* PWR_MODE = "LOW" *) (* KEEP = "TRUE" *) wire [7:0] nvaddr = VADDR[7:0] + 8'h01;
   always @(negedge CLKx4)
     if (!CLKx2 && !nAE)        // mid gigatron cycle
       begin
          if (! nOL)
            // Snooping starts when an OUT instruction reads memory
            // outside page zero and stop on any other OUT opcode.
            snoop <=  snoopchg;
          if (! nOL && ! nGOE)
            // Reset snooping address when an OUT reads memory
            VADDR <= GA;
          else
            // Otherwise increment address to next pixel
            VADDR[7:0] <= nvaddr;
       end
   
   /* Video output register */
   always @(negedge CLKx4)
     begin
        // sync
        if (!CLKx2 && nAE && !nOL)
          OUTD[7:6] = ALU[7:6];
        // first half pixel
        if (!CLKx2 && nAE)
          OUTD[5:0] = (snoop) ? 6'h20 : 6'h00; // (snoop) ? RD[5:0] : 6'h00;
     end
   /* Video output register 
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   /* Ctrl detection */
   wire nCTRL;
   assign nCTRL = nGOE || nGWE;
   assign nACTRL = nCTRL || GA[3:2] != 2'b00;
   assign nADEV[0] = (GA[7:4] == 4'b0000);
   assign nADEV[1] = (GA[7:4] == 4'b0001);
   
   /* Ctrl bits */
   always @(posedge nCTRL)
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
             if (GA[1:0] == 2'b11) // System reset
               begin
                  BANK0R[3:0] <= 4'b0;
                  BANK0W[3:0] <= 4'b0;
                  VBANK[3:0] <= 4'b0;
               end
          end
        /* Extended ctrl code */
        else
          case (GA[7:4])
            4'hf : begin        // Device 0xf : extended banking
               BANK0R[3:0] <= GA[11:8];
               BANK0W[3:0] <= GA[15:12];
            end
            4'he : begin        // Decide 0xe : set video bank
               VBANK[3:0] <= GA[11:8];
            end
          endcase
     end

endmodule

/* Local Variables: */
/* indent-tabs-mode: () */
/* End: */
