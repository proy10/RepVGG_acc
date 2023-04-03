/*
	Input size: 56*56*64
	Output size: 56*56*64

	Analysis:
	We need 128 conv kernel(64 3*3 kernel and 64 1*1 kernel), of which size is 3*3*64 and 1*1*64. 
	A PE can do a convolution operation. In hardware design, we will need 128*64 PEs. It's too many.

	Design solution:
	1. conv3*3 and conv1*1 use different module
	Use 8 PEs for 3*3 conv and 8 PEs for 1*1 conv. 
	2. conv3*3 and conv1*1 use the same module(VWA)
	Use 8 general PEs, which can process both 3*3 conv and 1*1 conv.

	We have several crucial modules: PE, accumulator, activator and control module.
*/

module accelerator();

	
endmodule
