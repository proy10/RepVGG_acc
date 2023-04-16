/*
	function: partial accumulation for 3x3 conv and 1x1 conv
	output: 56*32 bit
*/

module accumulator #(
	parameter DW = 32,
	parameter DP = 56,
	parameter CHNL_NUM = 3
)(
	input						clk,
	input						rst_n,
	input [CHNL_NUM*DW*DP-1:0]	data_i,
	input [DW*DP-1:0]			conv_res, //sum of origin and 1x1 conv

	output [DW*DP-1:0]			data_o
);

	reg [DW-1:0] s1_reg [0:DP-1];
	reg [DW-1:0] s2_reg [0:DP-1];
	reg [DW-1:0] s3_reg [0:DP-1];


	//s1
	genvar m;
	generate
		for(m=0; m<DP; m=m+1) begin: s1
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s1_reg[m] <= 0;
				end
				else begin
					s1_reg[m] <= data_i[DW*m+:DW];
				end
			end
	endgenerate

	//s2
	genvar n;
	generate
		for(n=0; n<DP; n=n+1) begin: s2
			always(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s2_reg[n] <= 0;
				end
				else begin
					s2_reg[n] <= s1_reg[n] + data_i[DW*(DP+n)+:DW] + conv_res;
				end
			end
		end
	endgenerate

	//s3
	genvar k;
	generate
		for(k=0; k<DP; k=k+1) begin: s3
			always(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s3_reg[k] <= 0;
				end
				else begin
					s3_reg[k] <= s2_reg[k] + data_i[DW*(2*DP+k)+:DW];
				end
			end
		end
	endgenerate


	genvar i;
	generate
		for(i=0; i<DP; i=i+1) begin: write
			assign data_o[DW*i+:DW] = s3_reg[i];
		end
	endgenerate

endmodule
