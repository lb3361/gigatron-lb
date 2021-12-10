

module main(
    input            CLK,
    input            CLKx2,
    input            CLKx4,
    output reg [7:0] OUTD,
    input [7:0]      ALU,
    input            nOL,
    output reg       nAE,
    output [18:0]    RA,
    input [7:0]      RDIN,
    output [7:0]     RDOUT,
    output           nROE,
    output           nRWE,
    input [15:0]     GA,
    input [7:0]      GBUSIN,
    output reg [7:0] GBUSOUT,
    input            nGOE,
    input            nGWE,
    output           nACTRL,
    output [1:0]     nADEV,
    output reg       SCK,
    input            MISO,
    output reg       MOSI,
    output reg [1:0] nSS,
    inout [4:3]      XIN );

   reg               SCLK;      // Ctrlbit 0   (sclk on)
   reg               nZPBANK;   // Ctrlbit 5   (zero page banking)
   reg [1:0]         BANK;      // Ctrlbit 7:6 (selected bank)
   reg [3:0]         BANK0R;    // Actual bank to read from when BANK=0
   reg [3:0]         BANK0W;    // Actual bank to write to when BANK=0

   reg               VRUN;      // automatic video generation
   reg [7:1]         VCNT;      // pixel counter
   reg [15:0]        VADDR;     // video address
   reg               HDBL;      // double horizontal pixels
   reg               nBE;       // strobe for first video memory access
   
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
    *                              ____________     ___________     _____
    *  /BE                                     \___/___/       \___/___/
    *                                              ^ downedge(CLKx4) & /CLKx2 & AE
    */

   /* Define /AE and /BE */
   always @(negedge CLKx4)
     begin
        if (CLKx2)
          begin
             nAE <= !CLK;
             nBE <= CLK;
          end
        else if (nAE & HDBL)
          begin
             nBE <= 1;
          end
     end

   /* Gigatron data bus output */
   wire portenable = SCLK && (GA == 16'h0000 || GA[15:4] == 12'h00F);
   always @*
     if (! nAE) // Transparently latched when nAE==0
       GBUSOUT = (!SCLK) ? RDIN :                                 // ram data
                 (GA == 16'h0000) ? { BANK, XIN, 3'b000, MISO } : // spi data
                 (GA == 16'h0080) ? { BANK0W, BANK0R} :           // bank data
                 RDIN;                                            // ram data

   /* Ram address bus */
   wire bankenable = GA[15] ^~ (!nZPBANK && GA[14:7] == 8'h01);
   wire [3:0] ghiaddr = (!bankenable) ? { 4'b0000 } :       // Nonbanked space
                        (BANK != 2'b00) ? { 2'b00, BANK } : // BANK=1,2,3
                        (nGOE) ? BANK0W : BANK0R;           // BANK=0
   assign RA = (! nAE) ? { ghiaddr, GA[14:0] } :       // Gigatron address
               { VADDR[15], nBE, 2'b00, VADDR[14:0] }; // Video address

   /* Ram control */
   assign nROE = (! nAE) ? nGOE : !VRUN;
   assign nRWE = (! nAE) ? (nGWE && !nGOE) : 1'b1;

   /* Ram data bus output (only reaches the pins when nROE=1) */
   assign RDOUT = GBUSIN;


   /* Video address and counter */
   always @(negedge CLKx4)
     begin
        if (!nAE && !CLKx2)     // middle of gigatron cycle
          begin
             if (!nOL && !nGOE)
               // Hmmmm : detecting rows does not seem to work like this....
          end
        if (nAE && !CLKx2)      // 20ns before CLK rising
          begin
             if (!nOL && ALU[7:6] != 2'b11)
               VCNT <= 8'd0;    // stop output when hsync or vsync is touched
          end
     end
   // TODO
   
   /* Video data */
   always @(negedge CLKx4)
     begin
        if (VRUN && VCNT != 8'd0)
          begin
             if (AE & !CLKx2)
               OUTD[5:0] <= RD[5:0];   // first pixel
             if (HDBL && CLK && CLKx2)
               OUTD[5:0] <= RD[5:0];   // second pixel 
          end
        if (!nOL && AE && !CLKx2)
          begin
             OUTD[7:6] <= ALU[7:6];    // HSn`YNC/VSYNC from Gigatron
             if (!VRUN)
               OUTD[5:0] <= ALU[5:0];  // Normal gigatron generation
          end
     end

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
             VRUN <= 1'b0;      // Disable video snooping
             HDBL <= 1'b0;
             BANK0R <= 4'b0;    // Reset bank0 mapping
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
          case (GA[7:4])        // Device 0xf : set BANK0W/R
            4'hf : begin
               BANK0R <= GA[11:8];
               BANK0W <= GA[15:12];
            end
            4'he : begin        // Decide 0xe : set video snooping
               VRUN <= GA[15];
               HDBL <= GA[14];
            end
          endcase
     end

   /* XIN used purely as input.
    * This could also be used to output 
    * a signal for debugging purposes */
   assign XIN = 2'bZ;
    
endmodule
