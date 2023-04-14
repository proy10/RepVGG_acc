/*
	Function: Channel accumulation
	Input: 56 column result of conv for 3 path.
	There are 64 channel, so we need to compute 63 times accumulation for 1 conv kernel and a 56*56*64 feature map. We can output column by column when the column complete 63 accumulation.
*/


module chnl_acum #(
	parameter DW = 32,
	parameter HIT = 56,
	parameter WID = 56
)(
	input						clk,
	input						rst_n,
	input [DW*HIT-1:0]			data_i,
	input						valid,
	
	output [DW*HIT-1:0]			data_o
);

	reg [5:0] cnt, chnl_cnt;
	reg [DW-1:0] mems [0:HIT-1][0:WID-1];

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			cnt <= 0;
		else if(valid) begin
			if(cnt == 55)
				cnt <= 0;
			else
				cnt <= cnt + 1;
		end
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			chnl_cnt <= 0;
		else if(cnt == 55) begin
			if(chnl_cnt == 55)
				chnl_cnt <= 0;
			else
				chnl_cnt <= chnl_cnt + 1;
	end

	

endmodule
