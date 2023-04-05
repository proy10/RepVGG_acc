/*
	Input: 7 data of feature map, 3 of weight
	Output: 9 MAC result

	All feature maps and weights are 32 bits signed data, which is Q24.8. Datapath should be fix-point. 
*/

`include "mul.v"

module pe3x3 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 9,
	parameter WEIGHT_NUM = 3,
	parameter IW = 24,
	parameter FW = 8
	//parameter DW_IN = 16,
	//parameter DW_ADD = 32,
	//parameter DW_MUL = 16,
	//parameter DW_OUT = 32
	)(
	input 									clk,
	input [INPUT_NUM*(IW+FW)-1:0]			fmap_i,
	input [WEIGHT_NUM*(IW+FW)-1:0] 			wht_i,

	output [OUTPUT_NUM*(IW+FW)-1:0] 		res_o
);

	wire [IW+FW-1:0] fmap_regs [0:INPUT_NUM-1];
	wire [IW+FW-1:0] wht_regs [0:WEIGHT_NUM-1];
	wire [IW+FW-1:0] MulRes_regs [0:INPUT_NUM-1][0:WEIGHT_NUM-1];
	reg [IW+FW-1:0] res_regs [0:OUTPUT_NUM-1];
	
	//assign fmap_regs = ifmap;
	//assign wht_regs = iwht;
	genvar m;
	generate
		for(m=0; m<INPUT_NUM; m=m+1) begin
			assign fmap_regs[m] = fmap_i[m+IW+DW-1:m];
		end
	endgenerate

	genvar n;
	generate
		for(n=0; n<WEIGHT_NUM; n=n+1) begin
			assign wht_regs[n] = wht_i[n+IW+DW-1:n];
		end
	endgenerate

	genvar k;
	generate
		for(k=0; k<OUTPUT_NUM; k=k+1) begin
			assign res_o[k+IW+DW-1:k] = res_regs[k];
		end
	endgenerate

	//multiplier instantiaton
	genvar i, j;
	generate
		for(i=0; i<INPUT_NUM; i=i+1) begin
			for (j=0; j<WEIGHT_NUM; j=j+1) begin
				mul u_mul #(
					.IW(IW),
					.FW(FW)
					)(
					.clk(clk), 
					.fmap(fmap_regs[i]),
					.wht(wht_regs[j]),
					.res(MulRes_regs[i][j])
				);
			end
		end
	endgenerate

	//compute partial sum
	always@(*) begin
		res_regs[0] = MulRes_regs[0][2];
		res_regs[1] = MulRes_regs[0][1] + MulRes_regs[1][2];
		res_regs[2] = MulRes_regs[0][0] + MulRes_regs[1][1] + MulRes_regs[2][2];
		res_regs[3] = MulRes_regs[1][0] + MulRes_regs[2][1] + MulRes_regs[3][2];
		res_regs[4] = MulRes_regs[2][0] + MulRes_regs[3][1] + MulRes_regs[4][2];
		res_regs[5] = MulRes_regs[3][0] + MulRes_regs[4][1] + MulRes_regs[5][2];
		res_regs[6] = MulRes_regs[4][0] + MulRes_regs[5][1] + MulRes_regs[6][2];
		res_regs[7] = MulRes_regs[5][0] + MulRes_regs[6][1];
		res_regs[8] = MulRes_regs[6][0];
	end
	
endmodule


module pe1x1 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 9,
	parameter WEIGHT_NUM = 1,
	parameter IW = 24,
	parameter FW = 8
	)(
	input 									clk,
	input [INPUT_NUM*(IW+FW)-1:0]			fmap_i,
	input [WEIGHT_NUM*(IW+FW)-1:0] 			wht_i,

	output [OUTPUT_NUM*(IW+FW)-1:0] 		res_o
);

	wire [IW+FW-1:0] fmap_regs [0:INPUT_NUM-1];
	wire [IW+FW-1:0] MulRes_regs [0:INPUT_NUM-1][0:WEIGHT_NUM-1];
	reg [IW+FW-1:0] res_regs [0:OUTPUT_NUM-1];

endmodule
