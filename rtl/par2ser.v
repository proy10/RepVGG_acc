module par2ser #(
	parameter DWI = 7*32,
	parameter DWO = 32
)(
	input			clk,
	input			rst_n,
	input			wen,
	input			ren,
	input [DWI-1:0]		din,

	output [DWO-1:0]	dout
);

	reg [DWI-1:0] shift;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			shift <= 0;
		else if(wen)
			shift <= din;
		else if(ren)
			shift <= {{DWO{1'b0}}, shift[(DWI-1)-:DWO]};
	end

	assign dout = shift[DWO-1:0];

endmodule
