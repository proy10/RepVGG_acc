module ser2par #(
	parameter DWI = 4*8,
	parameter DWO = 14*8
)(
	input			clk,
	input			rst_n,
	input			en,
	input [DWI-1:0]		din,

	output [DWO-1:0]	dout
);

	reg [DWO-1:0] shift;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			shift <= 0;
		else if(en)
			shift <= {shift[DWO-DWI-1:0], din};
	end

	assign dout = shift;

endmodule
