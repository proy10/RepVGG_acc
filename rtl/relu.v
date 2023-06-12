module relu #(
	parameter DW = 7*32
)(
	input			clk,
	input			rst_n,
	input			en,
	input [DW-1:0]		din,

	output reg [DW-1:0]	dout
);

	wire [DW-1:0] res;

	genvar i;
	generate
		for(i=0; i<7; i=i+1) begin: relu
			assign res[i*32+:32] = (!din[(i+1)*32-1]) ? din[i*32+:DW] : {32{1'b0}};
		end
	endgenerate

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			dout <= {DW{1'b0}};
		else if(en)
			dout <= res;
	end

endmodule
