/*
	Input feature map size: 56*56*64
	Output feature size: 56*56*64

	Analysis:
	We need 128 conv kernel(64 3*3 kernel and 64 1*1 kernel), of which size is 3*3*64 and 1*1*64. 
	We will do 56*56*64*64 times of 3*3 convolution operation and 56*56*64*64 times of 1*1 convolution operation.

	Design solution:
	1. (Data Reuse)conv3*3 and conv1*1 use different module
	Use 8 PEs for 3*3 conv. The PE is a 7*3 array, hence 8 PEs consist of a 56*3 array. A 3*3 PE computes MAC of 3 weights and 7 data of feature map at a time, so this array can complete 1 column of kernel(3 weights) and 1 column of feature map(56 data) in one cycle. 

	HOW TO DEAL PADDING?
	Buffer1 stores the sum of product of the 2nd weight and the 1st feature and the product of 3rd weight and 2nd feature. It's equal to that the 1st weight multiplie zero, which is the padding. It's the same with Buffer7. 
	As a result, take padding into consideration, it takes 3*56-2 cycles for one channel of feature map to complete 3*3 conv(don't consider the cost for sum).

	Use 8 PEs for 1*1 conv. It takes 56 cycles for one channel.
	
	We use a ser2par module and a par2ser module to process feature map input and output. For a ser2par module, its memory capacity is 56*4B=224B. 
	We use a reg of 9*4B=36B to store 3*3 kernel weights.

	2. (Module Reuse)conv3*3 and conv1*1 use the same module(VWA)
	Use 8 general PEs, which can process both 3*3 conv and 1*1 conv.

	We have several crucial modules: PE, accumulator, activator and controller.
*/

module accelerator #(
	parameter DW = 32,
	parameter PE_NUM = 8,
	parameter IW = 24,
	parameter FW = 8
)(
	input 			clk,
	input			rst_n,
	input [DW-1:0]	fmap_i,
	input [DW-1:0]	wht,
	input			valid,

	output			ready,
	output [DW-1:0]	res_o
);

	sirv_sim_ram u_ram(
		.clk(clk),
		.din(),
		.addr(),
		.cs(),
		.we(),
		.wem(),
		.dout()
	);
	
	genvar i;
	generate
		for(i=0; i<PE_NUM; i=i+1) begin: PE_init
			pe3x3 #(
				.INPUT_NUM(7),
				.OUTPUT_NUM(9),
				.WEIGHT_NUM(3),
				.IW(IW),
				.FW(FW)
			)
			u_pe3x3(
				.clk(clk),
				.rst_n(rst_n),
				.fmap_i(),
				.wht_i(),
				.array_i_0(),
				.array_i_1(),
				.config(),

				.res_o()
			);

			pe1x1 #(
				.INPUT_NUM(7),
				.OUTPUT_NUM(9),
				.IW(IW),
				.FW(FW)
			)
			u_pe1x1(
				.clk(clk),
				.rst_n(rst_n),
				.fmap_i(),
				.wht_i(),
				.active(),

				.res_o()
			);
		end
	endgenerate
endmodule
