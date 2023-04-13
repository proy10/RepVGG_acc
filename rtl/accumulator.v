module accumulator#(
	parameter DW = 32,
	parameter DP = 56,
	parameter REG_NUM = 3
)(
	input						clk,
	input						rst_n,
	input [REG_NUM*DW*DP-1:0]	data_i,

	output [DW*DP-1:0]			data_o
);

	reg [DW-1:0] s1_reg [0:DP-1];
	reg [DW-1:0] s2_reg [0:DP-1];
	reg [DW-1:0] s3_reg [0:DP-1];
	
	genvar t;
	generate
		for(t=0; t<REG_NUM; t=t+1) begin: read_psum
			
		end
	endgenerate


	//s1
	genvar m;
	generate
		for(m=0; m<DP; m=m+1) begin: s1
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s1_reg[m] <= 0;
				end
				else begin
					s1_reg[m] <= 
				end
			end
	endgenerate

endmodule
