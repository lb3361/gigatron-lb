

module gigatron_alu(input [7:0]  a,
                    input [7:0]  b,
                    input [3:0]  ar,
                    input        al,
                    output [7:0] alu,
                    output       cout);
   
   (* KEEP = "TRUE" *) wire [7:0] l, r;
   assign l = (al) ? a : 8'h00;
   assign r = { ar[{b[7],a[7]}], ar[{b[6],a[6]}], ar[{b[5],a[5]}], ar[{b[4],a[4]}],
                ar[{b[3],a[3]}], ar[{b[2],a[2]}], ar[{b[1],a[1]}], ar[{b[0],a[0]}] };
   assign {cout, alu} = l + r + ar[0];
endmodule
  

module gigatron(input             clk,
                input             reset_n,
                output reg [15:0] pc,
                input [15:0]      romdata,
                output [15:0]     addr,
                inout [7:0]       bus,
                output            oe_n,
                output            rw_n,
                output reg [7:0]  out,
                output reg [7:0]  xout,
                output            ie_n
                );
                                   
   /* declarations */
   
   (* KEEP = "TRUE" *) reg [7:0]  gbus;
   reg [7:0]                      ir, d;
   reg [7:0]                      ac, x, y;
   wire                           cout;
   wire                           pl, ph;
   
   /* Program counter */
   wire [15:0] nextpc = pc + 16'b1;
   always @(posedge clk)
     if (! reset_n)
       pc <= 16'h0000;
     else
       begin
          pc[7:0] <= (pl) ? gbus : nextpc[7:0];
          pc[15:8] <= (ph) ? y : (pl) ? pc[15:8] : nextpc[15:8];
       end   

   /* Program rom */
   always @(posedge clk)
     begin
        ir <= romdata[7:0];
        d <= romdata[15:8];
     end
   wire [1:0] ir_bus = ir[1:0];
   wire [2:0] ir_mode = ir[4:2];
   wire [2:0] ir_op   = ir[7:5];
   
   /* Bus */
   always @*
     case( ir_bus )
       2'b00: gbus = d;
       2'b01: gbus = bus;       // ram on external bus
       2'b10: gbus = ac;
       2'b11: gbus = bus;       // input on external bus
     endcase
   assign oe_n = (ir_bus != 2'b01);
   assign ie_n = (ir_bus != 2'b11);
   assign bus = (ir_bus[0]) ? 8'hZZ : gbus;
   
   /* Instruction decoder */                                
   reg [3:0]  ar;
   reg        al;
   wire       is_store = (ir_op == 3'b110);
   wire       is_jump = (ir_op == 3'b111);
   always @*
     case (ir_op)
       3'b000: { al, ar } = 5'b01100; // LOAD
       3'b001: { al, ar } = 5'b01000; // AND
       3'b010: { al, ar } = 5'b01110; // OR
       3'b011: { al, ar } = 5'b00110; // XOR
       3'b100: { al, ar } = 5'b11100; // ADD
       3'b101: { al, ar } = 5'b10011; // SUB
       3'b110: { al, ar } = 5'b10000; // STORE
       3'b111: { al, ar } = 5'b00101; // JUMP
     endcase // case (ir_op)

   /* Branch condition decoder */
   wire [3:0] bcond = { 1'b0, ir_mode };
   wire       branch_taken = bcond[{cout, ac[7]}];
      
   /* Address mode decoder */
   (* KEEP = "TRUE" *) reg [7:0]  ad;
   wire     ld, ol, el, eh, yl, xl, ix, lj;
   assign { ld, ol, el, eh, yl, xl, ix, lj } = ad;
   always @*
     case ( ir_mode )
       3'b000: ad = { !is_store, 7'b000_0001 };      // [D],AC
       3'b001: ad = { !is_store, 7'b010_0000 };      // [X],AC
       3'b010: ad = { !is_store, 7'b001_0000 };      // [Y,D],AC
       3'b011: ad = { !is_store, 7'b011_0000 };      // [Y,X],AC
       3'b100: ad = { 8'b0000_0100 };                // [D],X
       3'b101: ad = { 8'b0000_1000 };                // [D],Y
       3'b110: ad = { 1'b0, !is_store, 6'b00_0000 }; // [D],OUT
       3'b111: ad = { 1'b0, !is_store, 6'b11_0010 }; // [Y,X++],OUT
     endcase
   assign ph = is_jump && lj;
   assign pl = is_jump && (lj || branch_taken);
   
   /* Ram addresses and control */
   assign addr[7:0] = (el) ? x : d;
   assign addr[15:8] = (eh) ? y : 8'h00;
   assign rw_n = (is_store) ? clk : 1'b1;

   /* Arithmetic and logic unit */
   wire [7:0] alu;
   gigatron_alu galu(ac, gbus, ar, al, alu, cout);

   /* Registers */
   always @(posedge clk)
    if (ld) 
      ac <= alu;
   always @(posedge clk)
    if (yl) 
      y <= alu;
   always @(posedge clk)
     if (xl) 
       x <= alu;
     else if (ix)
       x <= x + 8'h01;
   always @(posedge clk)
     if (ol)
       out <= alu;
   always @(posedge clk)
     if (ol && alu[6] && !out[6]) // postive hsync edge
       xout <= ac;

endmodule // gigatron

                
