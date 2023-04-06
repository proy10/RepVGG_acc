module mul #(
	parameter IW = 24,
	parameter FW = 8
	)(
	input signed [IW+FW-1:0]		fmap,
	input signed [IW+FW-1:0]		wht,
	
	output signed [IW+FW-1:0]		res
);
	
	wire signed [(IW+FW)*2-1:0] long_res;

	assign long_res = fmap * wht;
	//disgard high 24 bits and low 8 bits.
	assign res = long_res_reg >>> FW;

endmodule
