`timescale 1ns/1ps

`define IW = 24
`define FW = 8
`define INPUT_NUM = 56
`define WEIGHT_NUM = 3
`define OUTPUT_NUM = 9

module pe_tb();
	reg clk;
	reg rst_n;

	initial begin
		clk = 1'b0;
	end

	forever begin
		#5 clk = ~clk;
	end

	initial begin
		rst_n = 1'b1;
		#10 rst_n = 1'b0;
		#10 rst_n = 1'b1;
	end

	reg signed [INPUT_NUM*(IW+FW)-1:0] fmap_i;
	reg signed [WEIGHT_NUM*(IW+FW)-1:0] wht_i;

	integer i, j;
	initial begin
		for(i=0; i<INPUT_NUM; i=i+1) begin: init_fmap
			fmap_i[i*(IW+FW)+:(IW+FW-1)] = i;
		end
	end	

	initial begin
		for(j=0; j<WEIGHT_NUM; j=j+1) begin: init_wht
			wht_i[j*(IW+FW)+:(IW+FW-1)] = j + 1;
		end
	end

	wire signed [OUTPUT_NUM*(IW+FW)-1:0] res;

	pe3x3 u_pe #(
		.INPUT_NUM(INPUT_NUM),
		.OUTPUT_NUM(OUTPUT_NUM),
		.WEIGHT_NUM(WEIGHT_NUM),
		.IW(IW),
		.FW(FW)
	)(
		.clk(clk),
		.rst_n(rst_n),
		.fmap_i(fmap_i),
		.wht_i(wht_i),
		.array_i_0(0),
		.array_i_1(0),
		.config(0),
		.res_o(res)
	);

endmodule
