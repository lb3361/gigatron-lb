module gigaexp(
    input A15,
    input A14TO8,
    input [7:0] A,
    inout [7:0] BUS,
    input nOE,
    input nWE,
    output nOERAM,
    output nWERAM,
    output A15R,
    output A16R,
    output MOSI,
    output SCK,
    output SCK0,
    output nSS0,
    output nSS1,
    input MISO0,
    input MISO1,
    inout SDA,
    inout SCL	 
	 );


wire oe = !nOE;
wire we = !nWE;
     
reg dat, clk, spol, sclk;
reg ss0, ss1, ssi2c;
reg b0, b1, zpbank;

assign nSS0 = !ss0;
assign nSS1 = !ss1;
assign SCK =  clk;
assign SCK0 = (ss0 & clk);   
assign MOSI = (ss0 | ss1) ? dat : 1'b1;
assign SDA = (ssi2c && !dat) ? 1'b0 : 1'bZ;
assign SCL = (ssi2c && !clk) ? 1'b0 : 1'bZ;

/* Ctrl instruction */

/* The format of the ctrl instruction is as follows
    CTRL yyyyyyyy,dddddddd
 	 |        |||||| +-- SCLK      : Clock output.
         |        ||||++---- /SS1 /SS0 : Port enable: SPI when one is zero, I2C when both are zero.
         |        |||+------ /CPOL     : Clock polarity.
         |        ||+------- /ZPBANK   : Enable zero-page banking when zero.
         |        ++-------- B1 B0     : Active memory bank.
         `------------------ DAT       : SPI/I2C data output.
			
	Notes:
	- Port inputs can be read in 0x00 when SCLK=1.
	- Actual clock is SCLK^CPOL. Toggling either SCLK or /CPOL toggles the clock.
	- There are two memory regions. The low region always shows bank 0. The high
	  region shows the bank specified by B1 and B0. When /ZPBANK==1, the low region
	  is 0x0000-0x7fff and the high region is 0x8000-0xffff. When /ZPBANK==0, the
          high region also contains the zero page range 0x0080-0x00ff but no longer
	  contains the range 0x8080-0x80ff.
	- SPI0 is selected when /SSO[1:0]==0b10.
	- SPI1 is selected when /SSO[1:0]==0b01.
	- I2C is selected when /SSO[1:0]==0b00.
	- When SPI is selected, DAT goes to MOSI, and SCLK^CPOL goes to SCK.
	- When I2C is selected, they go open-drain to SDA and SCL.
*/	

initial
 begin
  ss0 = 0;
  ss1 = 0;
  ssi2c = 0;
 end

always @(posedge(we))
 begin
   if (oe)
        begin
          dat <= A15;
          b1 <= A[7];
          b0 <= A[6];
          zpbank <= !A[5];
          spol <= !A[4];
          ss1 <= !A[3] && A[2];
          ss0 <= !A[2] && A[3];
          sclk <= A[0];
          /* derived */
          ssi2c <= !A[3] && !A[2];
          clk <= A[0] ^ !A[4];
       end
 end


/* Port control */

/* Reading 0x0000 when sclk gets the port data 
      -- If SPI0 is active, bit 2 shows MISO0.
      -- If SPI1 is active, bit 3 shows MISO1.
      -- If I2C is active, bit 1 shows SDA and bit 7 shows SCL.
      -- Also, if I2C is active, bit 6 is set when a transaction is ongoing.
      -- Also, if I2C is active, but 5 is set when we own the bus.  */

wire isport = !A15 && !A14TO8 && A[7:0]==8'b0 && sclk;
wire oeport = oe & !we & isport;
wire i2ctrans;
wire i2cmine;

assign BUS[0] = (oeport) ? A[7] : 1'bZ;
assign BUS[1] = (oeport) ? SDA & ssi2c & sclk : 1'bZ;
assign BUS[2] = (oeport) ? MISO0 & ss0 & sclk : 1'bZ;
assign BUS[3] = (oeport) ? MISO1 & ss1 & sclk : 1'bZ;
assign BUS[4] = (oeport) ? 1'b0 : 1'bZ;
assign BUS[5] = (oeport) ? i2cmine & ssi2c & sclk : 1'bZ;
assign BUS[6] = (oeport) ? i2ctrans & ssi2c & sclk : 1'bZ;
assign BUS[7] = (oeport) ? SCL & ssi2c & sclk : 1'bZ;


/* Ram control */

wire oeram = oe && !we && !isport;
wire weram = we && !oe;
assign nOERAM = !oeram;
assign nWERAM = !weram;

/* Ram banking */

wire bankenable = A15 ^ ( zpbank && !A14TO8 && A[7] );
assign A15R = bankenable && b0;
assign A16R = bankenable && b1; 

/* I2c arbitration */

reg i2c_r1, i2c_r2, i2c_mine;
assign i2ctrans = i2c_r1 ^ i2c_r2;
assign i2cmine = i2ctrans && i2c_mine;

always @(posedge SDA)
  begin
    if (SCL) /* STOP */
       i2c_r2 <= i2c_r1;            /* make i2ctrans zero */
  end

always @(negedge SDA)
  begin
    if (SCL) /* START */
       begin      
          i2c_r1 <= !i2c_r2;         /* make i2ctrans one */
          if (ssi2c && !dat)         /* we did it! */
            i2c_mine <= 1;
        end
     else     /* ZERO */
       begin    
          if (! (ssi2c && !dat))     /* we didn't do it! */
          i2c_mine <= 0;        
        end
  end

endmodule
