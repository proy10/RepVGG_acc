/*
	function: partial accumulation for 3x3 conv and 1x1 conv and origin
	output: 56*32 bit
*/

module accumulator #(
	parameter DW = 32,
	parameter DP = 56,
	parameter CHNL_NUM = 3
)(
	input						clk,
	input						rst_n,
	input [CHNL_NUM*DW*DP-1:0]	data_i_conv3,
	input [DW*DP-1:0]			data_i_conv1,
	input [DW*DP-1:0]			data_i_ori,

	output [DW*DP-1:0]			data_o
);

	reg [DW-1:0] reg_ori [0:DP-1];
	reg [DW-1:0] reg_ori2c1 [0:DP-1];
	reg [DW-1:0] s1_reg [0:DP-1];
	reg [DW-1:0] s2_reg [0:DP-1];
	reg [DW-1:0] s3_reg [0:DP-1];


	genvar i_ori;
	generate
		for(i_ori=0; i_ori<DP; i_ori=i_ori+1) begin: ori
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					reg_ori[i_ori] <= 0;
				else
					reg_ori[i_ori] <= data_i_ori[i_ori];
			end
		end
	endgenerate

	genvar i_o2c1;
	generate
		for(i_o2c1=0; i_o2c1<DP; i_o2c1=i_o2c1+1) begin: ori2c1
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					reg_ori2c1[i_o2c1] <= 0;
				else
					reg_ori2c1[i_o2c1] <= reg_ori[i_o2c1] + data_i_conv1[i_o2c1];
			end
		end
	endgenerate

	//s1
	genvar i_c12c3_s1;
	generate
		for(i_c12c3_s1=0; i_c12c3_s1<DP; i_c12c3_s1=i_c12c3_s1+1) begin: s1
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s1_reg[i_c12c3_s1] <= 0;
				end
				else begin
					s1_reg[i_c12c3_s1] <= data_i_conv3[DW*i_c12c3_s1+:DW];
				end
			end
	endgenerate

	//s2
	genvar i_c12c3_s2;
	generate
		for(i_c12c3_s2=0; i_c12c3_s2<DP; i_c12c3_s2=i_c12c3_s2+1) begin: s2
			always(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s2_reg[i_c12c3_s2] <= 0;
				end
				else begin
					s2_reg[i_c12c3_s2] <= s1_reg[i_c12c3_s2] + data_i_conv3[DW*(DP+i_c12c3_s2)+:DW] + data_i_conv1;
				end
			end
		end
	endgenerate

	//s3
	genvar i_c12c3_s3;
	generate
		for(i_c12c3_s3=0; i_c12c3_s3<DP; i_c12c3_s3=i_c12c3_s3+1) begin: s3
			always(posedge clk or negedge rst_n) begin
				if(!rst_n) begin
					s3_reg[i_c12c3_s3] <= 0;
				end
				else begin
					s3_reg[i_c12c3_s3] <= s2_reg[i_c12c3_s3] + data_i_conv3[DW*(2*DP+i_c12c3_s3)+:DW];
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
