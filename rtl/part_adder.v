module part_adder #(
	parameter DW = 288
)(
	input 			clk,
	input 			rst_n,
	input 			en,
	input [DW-1:0]		din,
	
	output [DW-1:0]		dout
);

	reg [DW-1:0] accum;

	integer i;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			for(i=0; i<7; i=i+1)
				accum[i*32+:32] <= {32{1'b0}};
		else if(en)
			for(i=0; i<7; i=i+1)
				accum[i*32+:32] <= accum[i*32+:32] + din[i*32+:32];
	end

	assign dout = accum;

endmodule
