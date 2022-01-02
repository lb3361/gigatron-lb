

/* Goal: Achieving parity with the V7 GAL-based boards.
   Bonus: Support for 512KB banking.
   Caveat: Replicating the DIP SRAM memory timing 
           might be too rough for the faster chip,
           especially in conjunction with the delay
           between the CLK2 and CLK2 Gigatron clocks. */

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
           output           nAE,
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
   
   reg                      SCLK;
   reg                      nZPBANK;
   reg [1:0]                BANK;
   reg [3:0]                BANK0R;
   reg [3:0]                BANK0W;
   reg [7:0]                GBUSOUT;
   wire [15:0]              GA;
   reg [18:0]               RA;

   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end
   
   assign nAE = 1'b0;
   assign RAL = 8'bZZZZZZZZ;
   assign nROE = nGOE;
   assign nRWE = nGWE || !nGOE;
   assign RD = (nGOE) ? GBUS : 8'bZZZZZZZZ;
   assign GA = { GAH, RAL };
   
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
   assign RAH = RA[18:8];

   wire misox;
   wire portx;
   assign misox = (MISO[0] & !nSS[0]) | (MISO[1] & !nSS[1]) | (MISO[2] & nSS[0] & nSS[1]);
   assign portx = SCLK && GAH[15:8] == 8'h00;
   always @*
     casez ( { portx, RAL[7:0] } )
       { 1'b1, 8'h00 } :   GBUSOUT = { BANK[1:0], XIN[4:3], 3'b000, misox }; // spi data
       { 1'b1, 8'hF0 } :   GBUSOUT = { BANK0W[3:0], BANK0R[3:0] };           // bank data
       default:            GBUSOUT = RD[7:0];                                // ram data
     endcase
   assign GBUS = (nGOE) ? 8'bZZZZZZZZ : GBUSOUT;

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
