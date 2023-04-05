/*
	Input size: 56*56*64
	Output size: 56*56*64

	Analysis:
	We need 128 conv kernel(64 3*3 kernel and 64 1*1 kernel), of which size is 3*3*64 and 1*1*64. 
	We will do 56*56*64*64 times of 3*3 convolution operation and 56*56*64*64 times of 1*1 convolution operation.

	Design solution:
	1. (Data Reuse)conv3*3 and conv1*1 use different module
	Use 8 PEs for 3*3 conv. A PE is a 7*3 array, hence 8 PEs consist of 56*3 array. A 3*3 PE computes 3 weights and 7 data of feature map at a time, so this array can compute 1 column of kernel(3 weights) and 1 column of feature map(56 data) in one cycle. Take padding into consideration. As a result, it takes 3*(56-3+1)+4 cycles for one channel of feature map to complete 3*3 conv(don't consider the cost for sum).
	Use 8 PEs for 1*1 conv. It takes 56 cycles for one channel.
	2. (Module Reuse)conv3*3 and conv1*1 use the same module(VWA)
	Use 8 general PEs, which can process both 3*3 conv and 1*1 conv.

	We have several crucial modules: PE, accumulator, activator and controller.
*/

module accelerator();

	
endmodule
