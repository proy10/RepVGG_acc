module mul #(
	//parameter DW_IN = 16,
	//parameter DW_OUT = 32
	parameter IW = 24,
	parameter FW = 8
	)(
	input							clk,
	input signed [IW+FW-1:0]		fmap,
	input signed [IW+FW-1:0]		wht,
	
	output signed [IW+FW-1:0]		res
);
	
	//reg signed [(IW+FW)*2-1:0] long_res;
	reg signed [IW+FW-1:0] res_reg;
	
	always@(posedge clk) begin
		res_reg <= (fmap * wht) >>> (FW * 2);
	end

	assign res = res_reg;

endmodule
