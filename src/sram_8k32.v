module sram_top

#(  parameter DW = 32,
  parameter MW = 4,
  parameter AW = 15 
)

(
  input             clk,
  input             rst, 
  input  [DW-1  :0] din, 
  input  [AW-1  :0] addr,
  input             cs,
  input             we,
  input  [MW-1:0]   wem,
  output [DW-1:0]   dout
);

  wire ceny,gweny;
  wire [DW-1:0] weny;
  wire [1:0] so;
  wire [AW-1:0] ay;
  wire [MW-1:0] wen;
  wire  [DW-1:0] wen_q;
  wire [DW-1:0] dout_pre;
  wire [14:0] addr_d;
  
  assign addr_d = {1'b0,addr};
  assign wen = ({MW{cs & we}} & wem);
  assign wen_q[7:0]   = wen[0] ? 0 : 8'hFF;
  assign wen_q[15:8]  = wen[1] ? 0 : 8'hFF;
  assign wen_q[23:16] = wen[2] ? 0 : 8'hFF;
  assign wen_q[31:24] = wen[3] ? 0 : 8'hFF; 
  
  sram_8kx32 sram_8kx32_u1(
   .CENY(ceny), 
   .WENY(weny), 
   .AY(ay), 
   .GWENY(gweny), 
   .Q(dout_pre), 
   .SO(so), 
   .CLK(clk), 
   .CEN(~cs), 
   .WEN(wen_q), 
   .A(addr_d), 
   .D(din), 
   .EMA(3'b010), 
   .EMAW(2'b00), 
   .TEN(1'b1),
   .TCEN(1'b1), 
   .TWEN(32'hFFFFFFFF), 
   .TA(addr_d), 
   .TD(din), 
   .GWEN(~we), 
   .TGWEN(1'b1), 
   .RET1N(1'b1), 
   .SI(2'b00), 
   .SE(1'b0), 
   .DFTRAMBYP(1'b0)  
   );


endmodule
