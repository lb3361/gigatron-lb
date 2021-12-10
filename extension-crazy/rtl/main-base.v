
module main(
    input            CLK,
    input            CLKx2,
    input            CLKx4,
    output reg [7:0] OUTD,
    input [7:0]      ALU,
    input            nOL,
    output           nAE,
    output [18:0]    RA,
    input [7:0]      RDIN,
    output [7:0]     RDOUT,
    output           nROE,
    output           nRWE,
    input [15:0]     GA,
    input [7:0]      GBUSIN,
    output [7:0]     GBUSOUT,
    input            nGOE,
    input            nGWE,
    output           nACTRL,
    output [1:0]     nADEV,
    output reg       SCK,
    input            MISO,
    output reg       MOSI,
    output reg [1:0] nSS,
    inout [4:3]      XIN );

   reg               SCLK;
   reg               nZPBANK;
   reg [1:0]         BANK;
   reg [3:0]         BANK0R;
   reg [3:0]         BANK0W;
   
   /* OUT Register (like a 74HC377) */
   always @(posedge CLK)
     begin
        if (!nOL)
          OUTD <= ALU;
     end

   /* XIN used purely as input.
    * This could also be used to output 
    * a signal for debugging purposes */
   assign XIN = 2'bZ;
   
   /* 74HCT244 always open.
    * Otherwise one could do something like:
    *   always @(negedge CLKx2)  nAE <= !CLK; */
   assign nAE = 1'b0;
   
   /* Ram address bus */
   wire zpbankenable = !nZPBANK && (GA[14:7] == 8'h01);
   wire bankenable = GA[15] ^~ zpbankenable;
   wire [3:0] ghiaddr = (!bankenable) ? { 4'b0000 } : 
              (BANK != 2'b00) ? { 2'b00, BANK } : 
              (nGOE) ? BANK0W : BANK0R; 
   assign RA = { ghiaddr, GA[14:0] };

   /* Ram data bus */
   assign RDOUT = GBUSIN;
   
   /* Gigatron bus out */
   assign GBUSOUT = (!SCLK) ? RDIN :                                 // ram data
                    (GA == 16'h0000) ? { BANK, XIN, 3'b000, MISO } : // spi data
                    (GA == 16'h0080) ? { BANK0W, BANK0R} :           // bank data
                    RDIN;                                            // ram data
   
   /* Ram control */
   assign nROE = nGOE;
   assign nRWE = nGWE | !nGOE;

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
             BANK0R <= 4'b0;
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

            
