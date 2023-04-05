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
	
	reg signed [(IW+FW)*2-1:0] long_res_reg;
	//reg signed [IW+FW-1:0] res_reg;
	
	always@(posedge clk) begin
		long_res_reg <= fmap * wht;
	end
	
	//disgard high 24 bits and low 8 bits.
	assign res = long_res_reg >>> FW;

endmodule
