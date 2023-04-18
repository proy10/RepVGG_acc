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
	reg [DW*HIT*WID-1:0] shift_regs;
	reg [3:0] shift_valid;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			shift_valid <= 4'b0;
		else
			shift_valid <= {shift_valid[2:0], valid};
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			cnt <= 0;
		else if(shift_valid[3]) begin
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
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			shift_regs <= 0;
		else if(shift_valid[3])
			shift_regs <= {shift_regs[DW*HIT*WID-1:DW*HIT], shift_regs[DW*HIT*WID-1-:DW*HIT]} + {(DW*HIT*(WID-1)){1'b0}, data_i};
	end

	assign data_o = (chnl_cnt == 55) ? shift_regs[DW*HIT-1:0] : 0;

endmodule
