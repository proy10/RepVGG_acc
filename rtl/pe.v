module pe (
	input 			clk,
	input 			rst_n,
	input			en,

	input signed [7*8-1:0]	ifm_i,
	input signed [3*8-1:0]	wht_i,

	output reg [9*32-1:0]	res_o
);

	wire signed [16-1:0] mul [0:6][0:2];

	genvar row, col;
	generate
		for(row=0; row<7; row=row+1) begin: mul_row
			for(col=0; col<3; col=col+1) begin: mul_col
				assign mul[row][col] = ifm_i[row*8+:8] * wht_i[col*8+:8];
			end
		end
	endgenerate

	wire [32-1:0] buffer [0:8];

	assign buffer[0] = {{16{mul[0][2][15]}}, mul[0][2]};
	assign buffer[1] = {{16{mul[0][1][15]}}, mul[0][1]} + {{16{mul[1][2][15]}}, mul[1][2]};

	genvar i;
	generate
		for(i=2; i<7; i=i+1) begin: buffer2_6
			assign buffer[i] = {{16{mul[i-2][0][15]}}, mul[i-2][0]} + {{16{mul[i-1][1][15]}}, mul[i-1][1]} + {{16{mul[i][1][15]}}, mul[i][1]};
		end
	endgenerate

	assign buffer[7] = {{16{mul[5][0][15]}}, mul[5][0]} + {{16{mul[6][1][15]}}, mul[6][1]};
	assign buffer[8] = {{16{mul[6][0][15]}}, mul[6][0]};

	integer i_rst;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			for(i_rst=0; i_rst<9; i_rst=i_rst+1)
				res_o[i_rst*32+:32] <= 32'h0;
		else if(en)
			for(i_rst=0; i_rst<9; i_rst=i_rst+1)
				res_o[i_rst*32+:32] <= buffer[i_rst];		
	end
endmodule
