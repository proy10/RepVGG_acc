/*
	Input: 7 of feature map, 3 of weight
	Output: 9 MAC result

	Note: 8 bit signed multiplie

	why use fix-point multiplie?
*/

module pe3x3 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 9,
	parameter WEIGHT_NUM = 3,
	parameter DW_IN = 8,
	parameter DW_ADD = 32,
	parameter DW_MUL = 16,
	)(
	input wire signed [INPUT_NUM*DW_IN-1:0]		ifmap,
	input wire signed [WEIGHT_NUM*DW_IN-1:0] 	iwht,

	output wire signed [OUTPUT_NUM*DW-1:0] 		data_o
);

	wire signed [0:INPUT_NUM-1][DW_IN-1:0]		fmap;
	wire signed [0:WEIGHT_NUM-1][DW_IN-1:0]	wht;
	
	assign fmap = ifmap;
	assign wht = iwht;

	genvar i;
	genvar j;
	generate
		for (i=0; i<INPUT_NUM; i=i+1) begin
			for (j=0; j<WEIGHT_NUM; j=j+1) begin
				
			end
		end
	endgenerate
	
endmodule
