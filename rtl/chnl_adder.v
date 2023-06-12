module chnl_adder #(
	parameter DWI = 9*32,
	parameter DWO = 7*32
)(
	input 			clk,
	input 			rst_n,
	input 			en,
	input [DWI-1:0]		din,
	
	output [DWO-1:0]	dout
);

	reg [DWO-1:0] accum;

	integer i;
	always@(posedge clk or negedge rst_n) begin
		for(i=0; i<7; i=i+1) begin: cadder
			if(!rst_n)
				accum[i*32+:32] <= {32{1'b0}};
			else if(en)
				accum[i*32+:32] = accum[i*32+:32] + din[(i*32+32)+:32];
		end
	end

	assign dout = accum;

endmodule
