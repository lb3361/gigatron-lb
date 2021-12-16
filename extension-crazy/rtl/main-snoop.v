

module main(
    input             CLK,
    input             CLKx2,
    input             CLKx4,
    output reg [7:0]  OUTD,
    input [7:0]       ALU,
    input             nOL,
    output reg        nAE,
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

   reg               SCLK;      // Ctrlbit 0   (sclk on)
   reg               nZPBANK;   // Ctrlbit 5   (zero page banking)
   reg [1:0]         BANK;      // Ctrlbit 7:6 (selected bank)
   reg [3:0]         BANK0R;    // Actual bank to read from when BANK=0
   reg [3:0]         BANK0W;    // Actual bank to write to when BANK=0

   reg               VRUN;      // automatic video generation
   reg [7:0]         VCNT;      // pixel counter
   reg [15:0]        VADDR;     // video address
   reg               HDBL;      // double horizontal pixels
   reg               VSNOOP;    // video snoop in progress
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

   /* Predicates to identify the four downedge CLKx4 */
   wire edge0 = CLKx2 && CLK;
   wire edge1 = !CLKx2 && !nAE;
   wire edge2 = CLKx2 && !CLK;
   wire edge3 = !CLKx2 && nAE;
   
   /* Gigatron data bus output */
   always @*
     if (! nAE) // Transparently latched when nAE==0
       casez ( { SCLK, GA } )
         { 1'b1, 16'h0000 } :   GBUSOUT = { BANK, XIN, 3'b000, MISO }; // spi data
         { 1'b1, 16'h0080 } :   GBUSOUT = { BANK0W, BANK0R };          // bank data
         default:               GBUSOUT = RDIN;
       endcase

   /* Ram address bus */
   wire bankenable = GA[15] ^~ (!nZPBANK && GA[14:7] == 8'h01);
   always @*
     casez ( { nAE, bankenable, BANK, nGOE } )
       5'b1???? :  RA = { nBE, VADDR[15], 2'b00, VADDR[14:0] }; // video snoop
       5'b00??? :  RA = { 4'b0000, GA[14:0] };                  // no banking
       5'b01000 :  RA = { BANK0R, GA[14:0] };                   // bank0, reading
       5'b01001 :  RA = { BANK0W, GA[14:0] };                   // bank0, maybe writing
       default  :  RA = { 2'b00, BANK, GA[14:0] };              // bank123
     endcase

   /* Ram control */
   assign nROE = !(nAE ? VRUN : !nGOE);
   assign nRWE = nGWE || !nGOE || nAE;  // avoid glitches

   /* Ram data bus output */
   assign RDOUT = GBUSIN;

   /* Video address and counter */
   always @(negedge CLKx4)
     begin
        if (edge1)
          begin
             if (!OUTD[6])
               begin            // hsync pulse
                  VCNT <= 8'd0;
                  VSNOOP <= 1'b0;
               end
             else if (!nOL && !VSNOOP && VCNT[7:5] == 3'b000)
               begin            // out within 32 cycles of end of hsync
                  VCNT <= 8'd0;
                  VSNOOP <= 1'b1;
                  VADDR <= GA;
               end
             else if (VCNT == 8'd159)
               begin            // last pixel
                  VSNOOP <= 1'b0;
               end
             else
               begin            // increment
                  VCNT <= VCNT + 8'd1;
                  VADDR[7:0] <= VADDR[7:0] + 8'd1;
               end
          end
     end
   
   /* Video data */
   always @(negedge CLKx4)
     begin
        if (edge3)
          begin
             if (VSNOOP)
               OUTD[5:0] <= RDIN[5:0];   // first pixel
             else if (!nOL)
               OUTD[5:0] <= ALU[5:0];    // pixel from Gigatron
             if (!nOL)
               OUTD[7:6] <= ALU[7:6];    // sync from Gigatron
          end
        if (edge0)
          begin
             if (VSNOOP && HDBL)
               OUTD[5:0] <= RDIN[5:0];   // second pixel
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
            4'b1111 : begin
               BANK0R <= GA[11:8];
               BANK0W <= GA[15:12];
            end
            4'b1110 : begin     // Device 0xe : set video snooping
               VRUN <= GA[15];
               HDBL <= GA[14];
            end
          endcase
     end

   /* XIN used purely as input.
    * This could also be used to output 
    * a signal for debugging purposes */
   //assign XIN = 2'bZ;
   assign XIN = { VSNOOP, nBE };
   
    
endmodule
