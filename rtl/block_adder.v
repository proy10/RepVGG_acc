module block_adder #(
	parameter DWI = 18*32,
	parameter DWO = 9*32
)(
	input 			clk,
	input 			rst_n,
	input			en,
	input [DWI-1:0]		din,

	output reg [DWO-1:0]	dout
);

	wire [DW-1:0] sum;
	
	genvar i;
	generate 
		for(i=0; i<9; i=i+1) begin: badder
			assign sum[i*32+:32] = din[i*32+:32] + din[(i*32+DWO)+:32];
		end
	endgenerate

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			dout <= {DWO{1'b0}};
		else if(en)
			dout <= sum;
	end

endmodule
