/*
	Input feature map size: 56*56*64
	Output feature size: 56*56*64

	Analysis:
	We need 128 conv kernel(64 3*3 kernel and 64 1*1 kernel), of which size is 3*3*64 and 1*1*64. 
	We will do 56*56*64*64 times of 3*3 convolution operation and 56*56*64*64 times of 1*1 convolution operation.

	Design solution:
	1. (Data Reuse)conv3*3 and conv1*1 use different module
	Use 8 PEs for 3*3 conv. The PE is a 7*3 array, hence 8 PEs consist of a 56*3 array. A 3*3 PE computes MAC of 3 weights and 7 data of feature map at a time, so this array can complete 1 column of kernel(3 weights) and 1 column of feature map(56 data) in one cycle. We use 3 such array to parallel computing produre.

	HOW TO DEAL PADDING?
	Buffer1 stores the sum of product of the 2nd weight and the 1st feature and the product of 3rd weight and 2nd feature. It's equal to that the 1st weight multiplie zero, which is the padding. It's the same with Buffer7. 
	As a result, take padding into consideration, it takes 56 cycles for one channel of feature map to complete 3*3 conv(don't consider the cost for sum).

	Use 8 PEs for 1*1 conv. It takes 56 cycles for one channel.
	
	We use a ser2par module and a par2ser module to process feature map input and output. For a ser2par module, its memory capacity is 56*4B=224B. 
	We use a reg of 9*4B=36B to store 3*3 kernel weights.

	2. (Module Reuse)conv3*3 and conv1*1 use the same module(VWA)
	Use 8 general PEs, which can process both 3*3 conv and 1*1 conv.

	We have several crucial modules: PE, accumulator, activator and controller.
*/

module accelerator #(
	parameter HIT = 56,
	parameter WID = 56,
	parameter WHT_NUM = 10,
	parameter DW = 32,
	parameter PE_NUM = 8,
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 9,
	parameter IW = 24,
	parameter FW = 8
)(
	input 							clk,
	input							rst_n,
	input [HIT*DW-1:0]				fmap_i,
	input [WHT_NUM*DW-1:0]			wht_i,
	input							valid,

	output							ready,
	output [HIT*DW-1:0]				data_o
);
	
	//pe3x3 init
	wire [3*DW-1:0] wht3x3 [0:2];
	wire [DW-1:0] array_i [0:PE_NUM-1][0:2][0:1];
	wire [OUTPUT_NUM*DW-1:0] res_3x3 [0:PE_NUM-1][0:2];

	genvar i_wht;
	generate
		for(i_wht=0; i_wht<3; i_wht=i_wht+1) begin: read_wht3x3
			assign wht3x3[i_wht] = wht_i[i_wht*3*DW+:3*DW];
		end
	endgenerate

	genvar j;
	generate
		for(j=0; j<3; j=j+1) begin: arr_init
			assign array_i[0][j][0] = 32'b0;
			assign array_i[0][j][1] = 32'b0;
		end
	endgenerate

	genvar i_arr, j_arr;
	generate
		for(i_arr=1; i_arr<PE_NUM; i_arr=i_arr+1) begin: arr_i_pe
			for(j_arr=0; j_arr<3; j_arr=j_arr+1) begin: arr_j_pe
				assign array_i[i_arr][j_arr][0] = res_3x3[i_arr-1][j_arr][(OUTPUT_NUM-2)*DW+:DW];
				assign array_i[i_arr][j_arr][1] = res_3x3[i_arr-1][j_arr][(OUTPUT_NUM-1)*DW+:DW];
			end
		end
	endgenerate

	genvar i_pe3, j_pe3;
	generate
		for(i_pe3=0; i_pe3<PE_NUM; i_pe3=i_pe3+1) begin: PE3x3
			for(j_pe3=0; j_pe3<3; j_pe3=j_pe3+1) begin: chnl
				pe3x3 #(
					.INPUT_NUM(INPUT_NUM),
					.OUTPUT_NUM(OUTPUT_NUM),
					.WEIGHT_NUM(3),
					.IW(IW),
					.FW(FW)
				) u_pe3x3(
					.clk(clk),
					.rst_n(rst_n),
					.fmap_i(fmap_i[INPUT_NUM*DW*i_pe3+:INPUT_NUM*DW]),
					.wht_i(wht3x3[j_pe3]),
					.array_i_0(array_i[i_pe3][j_pe3][0]),
					.array_i_1(array_i[i_pe3][j_pe3][1]),
					.config(1'b1),

					.res_o(res_3x3[i_pe3][j_pe3])
				);
			end
		end
	endgenerate

	//pe1x1 init
	wire [(OUTPUT_NUM-2)*DW-1:0] res_1x1 [0:PE_NUM-1];

	genvar i_pe1;
	generate
		for(i_pe1=0; i_pe1<PE_NUM; i_pe1=i_pe1+1) begin: PE1x1
			pe1x1 #(
				.INPUT_NUM(INPUT_NUM),
				.OUTPUT_NUM(7),
				.IW(IW),
				.FW(FW)
			) u_pe1x1(
				.clk(clk),
				.rst_n(rst_n),
				.fmap_i(fmap_i[INPUT_NUM*DW*i_pe1+:INPUT_NUM*DW]),
				.wht_i(wht_i[(WHT_NUM-1)*DW+:DW]),

				.res_o(res_1x1[i_pe1])
			);
		end
	endgenerate

	//accumulator init
	wire [DW*HIT-1:0] wire_i_conv1;
	wire [3*DW*HIT-1:0] wire_i_conv3;
	wire [DW*HIT-1:0] wire_o_acc_res;

	genvar i_conv1;
	generate
		for(i_conv1=0; i_conv1<PE_NUM; i_conv1=i_conv1+1) begin: wire_conv1
			assign wire_i_conv1[i_conv1*(OUTPUT_NUM-2)*DW+:(OUTPUT_NUM-2)*DW] = res_1x1[i_conv1];
		end
	endgenerate

	genvar i_conv3, j_conv3;
	generate
		for(i_conv3=0; i_conv3<3; i_conv3=i_conv3+1) begin: wire_conv3
			for(j_conv3=0; j_conv3<PE_NUM; j_conv3=j_conv3+1) begin: wire_conv3_chnl
				// discard high DW bits and low DW bits.
				assign wire_i_conv3[(i_conv3+j_conv3)*(OUTPUT_NUM-2)*DW+:(OUTPUT_NUM-2)*DW] = res_3x3[j_conv3][i_conv3][(OUTPUT_NUM-1)*DW-1:DW];
			end
		end
	endgenerate
	
	accumulator #(
		.DW(DW),
		.DP(HIT)
	) u_acum(
		.clk(clk),
		.rst_n(rst_n),
		.data_i_conv3(wire_i_conv3),
		.data_i_conv1(wire_i_conv1),
		.data_i_ori(fmap_i),

		.data_o(wire_o_accres)
	);

	//chnl_acum init
	wire [DW*HIT-1:0] wire_o_ch_acc_res;
	chnl_acum #(
		.DW(DW),
		.HIT(HIT),
		.WID(WID)
	) u_chac(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(wire_o_accres),
		.valid(valid),

		.data_o(wire_o_ch_acc_res)
	);

	//relu init
	//wire [DW*HIT-1:0] wire_o_relu_res;
	relu #(
		.DW(DW),
		.DP(HIT)
	) u_relu(
		.clk(clk),
		.rst_n(rst_n),
		.data_i(wire_o_ch_acc_res),

		.data_o(data_o)
	);
	
endmodule
