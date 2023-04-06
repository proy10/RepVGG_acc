/*
	Input: 7 data of feature map, 3 weights, 2 extra array input.
	Output: 9 MAC result

	There are 2 working mode, single and united, which can be set by input signal "config".
	All feature maps and weights are 32 bits signed data, which is Q24.8. Datapath should be fix-point. 
*/


module pe3x3 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 9,
	parameter WEIGHT_NUM = 3,
	parameter IW = 24,
	parameter FW = 8
	)(
	input 									clk,
	input 									rst_n,
	input [INPUT_NUM*(IW+FW)-1:0]			fmap_i,
	input [WEIGHT_NUM*(IW+FW)-1:0] 			wht_i,
	input [IW+FW-1:0]						array_i_0,
	input [IW+FW-1:0]						array_i_1,
	input									config, // 0 denotes single mode, 1 denotes united mode

	output [OUTPUT_NUM*(IW+FW)-1:0] 		res_o
);

	wire [IW+FW-1:0] fmap_regs [0:INPUT_NUM-1];
	wire [IW+FW-1:0] wht_regs [0:WEIGHT_NUM-1];
	wire [IW+FW-1:0] MulRes_regs [0:INPUT_NUM-1][0:WEIGHT_NUM-1];
	reg [IW+FW-1:0] res_regs [0:OUTPUT_NUM-1];
	
	genvar m;
	generate
		for(m=0; m<INPUT_NUM; m=m+1) begin: read_fmap
			assign fmap_regs[m] = fmap_i[m+IW+DW-1:m];
		end
	endgenerate

	genvar n;
	generate
		for(n=0; n<WEIGHT_NUM; n=n+1) begin: read_wht
			assign wht_regs[n] = wht_i[n+IW+DW-1:n];
		end
	endgenerate

	//multiplier instantiaton
	genvar i, j;
	generate
		for(i=0; i<INPUT_NUM; i=i+1) begin: row
			for (j=0; j<WEIGHT_NUM; j=j+1) begin: col
				mul u_mul #(
					.IW(IW),
					.FW(FW)
					)(
					//.clk(clk), 
					.fmap(fmap_regs[i]),
					.wht(wht_regs[j]),
					.res(MulRes_regs[i][j])
				);
			end
		end
	endgenerate

	//compute partial sum
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			/*res_regs[0] = 0;
			res_regs[1] = 0;
			res_regs[2] = 0;
			res_regs[3] = 0;
			res_regs[4] = 0;
			res_regs[5] = 0;
			res_regs[6] = 0;
			res_regs[7] = 0;
			res_regs[8] = 0;*/
			integer t;
			for(t=0; t<OUTPUT_NUM; t=t+1) begin: reset
				res_regs[t] = 0;
			end
		end
		else if(!config) begin
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
		else begin
			res_regs[0] = MulRes_regs[0][2] + array_i_0;
			res_regs[1] = MulRes_regs[0][1] + MulRes_regs[1][2] + array_i_1;
			res_regs[2] = MulRes_regs[0][0] + MulRes_regs[1][1] + MulRes_regs[2][2];
			res_regs[3] = MulRes_regs[1][0] + MulRes_regs[2][1] + MulRes_regs[3][2];
			res_regs[4] = MulRes_regs[2][0] + MulRes_regs[3][1] + MulRes_regs[4][2];
			res_regs[5] = MulRes_regs[3][0] + MulRes_regs[4][1] + MulRes_regs[5][2];
			res_regs[6] = MulRes_regs[4][0] + MulRes_regs[5][1] + MulRes_regs[6][2];
			res_regs[7] = MulRes_regs[5][0] + MulRes_regs[6][1];
			res_regs[8] = MulRes_regs[6][0];
		end
	end

	genvar k;
	generate
		for(k=0; k<OUTPUT_NUM; k=k+1) begin: write_res
			assign res_o[k+IW+DW-1:k] = res_regs[k];
		end
	endgenerate
	
endmodule


module pe1x1 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 7,
	parameter IW = 24,
	parameter FW = 8
	)(
	input 									clk,
	input 									rst_n,
	input [INPUT_NUM*(IW+FW)-1:0]			fmap_i,
	input [IW+FW-1:0] 						wht_i,

	output [OUTPUT_NUM*(IW+FW)-1:0] 		res_o
);

	wire [IW+FW-1:0] fmap_regs [0:INPUT_NUM-1];
	wire [IW+FW-1:0] MulRes_regs [0:INPUT_NUM-1];
	reg [IW+FW-1:0] res_regs [0:OUTPUT_NUM-1];

	genvar m;
	generate
		for(m=0; m<INPUT_NUM; m=m+1) begin: 
			assign fmap_regs[m] = fmap_i[m+IW+DW-1:m];
		end
	endgenerate

	genvar i;
	generate
		for(i=0; i<INPUT_NUM; i=i+1) begin: mul_instantiaton
			mul u_mul #(
				.IW(IW),
				.FW(FW)
				)( 
				.fmap(fmap_regs[i]),
				.wht(wht_i),
				.res(MulRes_regs[i])
			);
		end
	endgenerate

	always@(posedge clk or negedge rst_n) begin
		integer t;
		for(t=0; t<OUTPUT_NUM; t=t+1) begin: read_res
			res_regs[t] <= MulRes_regs[t];
		end
	end

	genvar k;
	generate
		for(k=0; k<OUTPUT_NUM; k=k+1) begin: write_res
			assign res_o[k+IW+DW-1:k] = res_regs[k];
		end
	endgenerate
	
endmodule
