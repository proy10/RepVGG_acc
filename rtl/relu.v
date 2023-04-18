module relu #(
	parameter DW = 32,
	parameter DP = 56
)(
	input					clk,
	input					rst_n,
	input [DP*DW-1:0]		data_i,

	output [DP*DW-1:0]		data_o
);

	reg [DP*DW-1:0] res;

	genvar i;
	generate
		for(i=0; i<DP; i=i+1) begin: relu
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					res[i*DW+:DW] <= 0;
				else
					res[i*DW+:DW] <= (!data_i[(i+1)*DW-1]) ? data_i[i*DW-:DW] : {DW{1'b0}};
			end
		end
	endgenerate

	assign data_o = res;

endmodule
