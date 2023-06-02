module ser2par (
	input			clk,
	input			rst_n,
	input			en,
	input [32-1:0]		din,

	output [56*16-1:0]	dout
);

	reg [56*16-1:0] shift_reg;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			shift_reg <= 0;
		else if(en)
			shift_reg <= {shift_reg[55*16-1:0], 8{din[7]}, din};
	end

	assign dout = (en) ? 0 : shift_reg;

endmodule
